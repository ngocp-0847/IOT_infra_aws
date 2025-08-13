# Lambda Python runtime base image
FROM public.ecr.aws/lambda/python:3.11

# Copy handler code
COPY lambda/query_handler.py ${LAMBDA_TASK_ROOT}/query_handler.py

# Install dependencies if you add a requirements.txt later
# COPY lambda/requirements.txt  .
# RUN pip install -r requirements.txt --target "${LAMBDA_TASK_ROOT}"

# Command can be overwritten by AWS Lambda runtime interface
CMD ["query_handler.handler"]


