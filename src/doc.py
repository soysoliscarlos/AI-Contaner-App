# Documents QA Chat: upload PDF/DOCX, embed with Azure OpenAI, store in ChromaDB, answer with RAG.
# Uses DefaultAzureCredential (set AZURE_CLIENT_ID for Managed Identity).
# See: https://github.com/Azure-Samples/container-apps-openai

import os
import io
import sys
import logging
import chainlit as cl
from pypdf import PdfReader
from docx import Document
from azure.identity import DefaultAzureCredential, get_bearer_token_provider
from dotenv import load_dotenv
from dotenv import dotenv_values

# LangChain: use langchain_community / langchain_openai if your version differs
try:
    from langchain_community.embeddings import AzureOpenAIEmbeddings
    from langchain_community.vectorstores import Chroma
    from langchain_openai import AzureChatOpenAI
except ImportError:
    from langchain.embeddings import AzureOpenAIEmbeddings
    from langchain.vectorstores.chroma import Chroma
    from langchain.chat_models import AzureChatOpenAI

from langchain.text_splitter import RecursiveCharacterTextSplitter
from langchain.chains import RetrievalQAWithSourcesChain
from langchain.prompts.chat import (
    ChatPromptTemplate,
    SystemMessagePromptTemplate,
    HumanMessagePromptTemplate,
)

if os.path.exists(".env"):
    load_dotenv(override=True)
    dotenv_values(".env")

temperature = float(os.environ.get("TEMPERATURE", 0.9))
api_base = os.getenv("AZURE_OPENAI_BASE")
api_key = os.getenv("AZURE_OPENAI_KEY")
api_type = os.getenv("AZURE_OPENAI_TYPE", "azure")
api_version = os.getenv("AZURE_OPENAI_VERSION", "2024-02-15-preview")
chat_completion_deployment = os.getenv("AZURE_OPENAI_DEPLOYMENT")
embeddings_deployment = os.getenv("AZURE_OPENAI_ADA_DEPLOYMENT") or os.getenv("AZURE_OPENAI_EMBEDDING_DEPLOYMENT")
model = os.getenv("AZURE_OPENAI_MODEL")
max_size_mb = int(os.getenv("CHAINLIT_MAX_SIZE_MB", 100))
max_files = int(os.getenv("CHAINLIT_MAX_FILES", 10))
text_splitter_chunk_size = int(os.getenv("TEXT_SPLITTER_CHUNK_SIZE", 1000))
text_splitter_chunk_overlap = int(os.getenv("TEXT_SPLITTER_CHUNK_OVERLAP", 10))
embeddings_chunk_size = int(os.getenv("EMBEDDINGS_CHUNK_SIZE", 16))
max_retries = int(os.getenv("MAX_RETRIES", 5))
retry_min_seconds = int(os.getenv("RETRY_MIN_SECONDS", 1))
retry_max_seconds = int(os.getenv("RETRY_MAX_SECONDS", 5))
timeout = int(os.getenv("TIMEOUT", 30))
debug = os.getenv("DEBUG", "False").lower() in ("true", "1", "t")

system_template = """Use the following pieces of context to answer the users question.
If you don't know the answer, just say that you don't know, don't try to make up an answer.
ALWAYS return a "SOURCES" part in your answer.
The "SOURCES" part should be a reference to the source of the document from which you got your answer.

Example of your response should be:

```
The answer is foo
SOURCES: xyz
```

Begin!
----------------
{summaries}"""
messages = [
    SystemMessagePromptTemplate.from_template(system_template),
    HumanMessagePromptTemplate.from_template("{question}"),
]
prompt = ChatPromptTemplate.from_messages(messages)
chain_type_kwargs = {"prompt": prompt}

logging.basicConfig(
    stream=sys.stdout,
    format="[%(asctime)s] {%(filename)s:%(lineno)d} %(levelname)s - %(message)s",
    level=logging.INFO,
)
logger = logging.getLogger(__name__)

token_provider = None
if api_type == "azure_ad":
    token_provider = get_bearer_token_provider(
        DefaultAzureCredential(), "https://cognitiveservices.azure.com/.default"
    )

if api_type == "azure":
    os.environ["AZURE_OPENAI_API_KEY"] = api_key or ""
os.environ["AZURE_OPENAI_API_VERSION"] = api_version
os.environ["AZURE_OPENAI_ENDPOINT"] = api_base or ""
os.environ["AZURE_OPENAI_DEPLOYMENT_NAME"] = chat_completion_deployment or ""


@cl.on_chat_start
async def start():
    await cl.Avatar(name="Chatbot", url="https://cdn-icons-png.flaticon.com/512/8649/8649595.png").send()
    await cl.Avatar(name="Error", url="https://cdn-icons-png.flaticon.com/512/8649/8649595.png").send()
    await cl.Avatar(name="You", url="https://media.architecturaldigest.com/photos/5f241de2c850b2a36b415024/master/w_1600%2Cc_limit/Luke-logo.png").send()

    files = None
    while files is None:
        files = await cl.AskFileMessage(
            content=f"Please upload up to {max_files} `.pdf` or `.docx` files to begin.",
            accept=[
                "application/pdf",
                "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
            ],
            max_size_mb=max_size_mb,
            max_files=max_files,
            timeout=86400,
            raise_on_timeout=False,
        ).send()

    content = f"Processing {', '.join([f.name for f in files])}..." if len(files) > 1 else f"Processing `{files[0].name}`..."
    logger.info(content)
    msg = cl.Message(content=content, author="Chatbot")
    await msg.send()

    all_texts = []
    for file in files:
        with open(file.path, "rb") as f:
            file_contents = f.read()
        logger.info("[%d] bytes read from %s", len(file_contents), file.path)
        buf = io.BytesIO(file_contents)
        extension = file.name.split(".")[-1].lower()
        text = ""
        if extension == "pdf":
            reader = PdfReader(buf)
            for i in range(len(reader.pages)):
                text += reader.pages[i].extract_text() or ""
        elif extension == "docx":
            doc = Document(buf)
            text = "\n".join(p.text for p in doc.paragraphs)
        splitter = RecursiveCharacterTextSplitter(
            chunk_size=text_splitter_chunk_size,
            chunk_overlap=text_splitter_chunk_overlap,
        )
        all_texts.extend(splitter.split_text(text))

    metadatas = [{"source": f"{i}-pl"} for i in range(len(all_texts))]

    if api_type == "azure":
        embeddings = AzureOpenAIEmbeddings(
            openai_api_version=api_version,
            openai_api_type=api_type,
            openai_api_key=api_key,
            azure_endpoint=api_base,
            azure_deployment=embeddings_deployment,
            max_retries=max_retries,
            retry_min_seconds=retry_min_seconds,
            retry_max_seconds=retry_max_seconds,
            chunk_size=embeddings_chunk_size,
            timeout=timeout,
        )
    else:
        embeddings = AzureOpenAIEmbeddings(
            openai_api_version=api_version,
            openai_api_type=api_type,
            azure_endpoint=api_base,
            azure_ad_token_provider=token_provider,
            azure_deployment=embeddings_deployment,
            max_retries=max_retries,
            retry_min_seconds=retry_min_seconds,
            retry_max_seconds=retry_max_seconds,
            chunk_size=embeddings_chunk_size,
            timeout=timeout,
        )

    db = await cl.make_async(Chroma.from_texts)(all_texts, embeddings, metadatas=metadatas)

    if api_type == "azure":
        llm = AzureChatOpenAI(
            openai_api_type=api_type,
            openai_api_version=api_version,
            openai_api_key=api_key,
            azure_endpoint=api_base,
            temperature=temperature,
            azure_deployment=chat_completion_deployment,
            streaming=True,
            max_retries=max_retries,
            timeout=timeout,
        )
    else:
        llm = AzureChatOpenAI(
            openai_api_type=api_type,
            openai_api_version=api_version,
            azure_endpoint=api_base,
            azure_deployment=chat_completion_deployment,
            azure_ad_token_provider=token_provider,
            temperature=temperature,
            streaming=True,
            max_retries=max_retries,
            timeout=timeout,
        )

    chain = RetrievalQAWithSourcesChain.from_chain_type(
        llm=llm,
        chain_type="stuff",
        retriever=db.as_retriever(),
        return_source_documents=True,
        chain_type_kwargs=chain_type_kwargs,
    )
    cl.user_session.set("metadatas", metadatas)
    cl.user_session.set("texts", all_texts)
    cl.user_session.set("chain", chain)

    msg.content = f"{', '.join([f.name for f in files])} processed. You can now ask questions." if len(files) > 1 else f"`{files[0].name}` processed. You can now ask questions!"
    msg.author = "Chatbot"
    await msg.update()


@cl.on_message
async def main(message: cl.Message):
    chain = cl.user_session.get("chain")
    cb = cl.AsyncLangchainCallbackHandler()
    response = await chain.acall(message.content, callbacks=[cb])
    logger.info("Question: [%s]", message.content)

    answer = response["answer"]
    sources = response["sources"].strip()
    source_elements = []
    metadatas = cl.user_session.get("metadatas")
    all_sources = [m["source"] for m in metadatas]
    texts = cl.user_session.get("texts")

    if sources:
        found_sources = []
        for source in sources.split(","):
            source_name = source.strip().replace(".", "")
            try:
                index = all_sources.index(source_name)
            except ValueError:
                continue
            found_sources.append(source_name)
            source_elements.append(cl.Text(content=texts[index], name=source_name))
        if found_sources:
            answer += f"\nSources: {', '.join(found_sources)}"
        else:
            answer += "\nNo sources found"

    await cl.Message(content=answer, elements=source_elements).send()
    if api_type == "azure_ad" and token_provider:
        os.environ["AZURE_OPENAI_API_KEY"] = token_provider()
