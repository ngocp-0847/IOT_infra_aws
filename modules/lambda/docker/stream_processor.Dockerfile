# Lambda Python runtime base image
FROM public.ecr.aws/lambda/python:3.11

# Copy handler code
COPY lambda/stream_processor.py ${LAMBDA_TASK_ROOT}/stream_processor.py

# Install dependencies if you add a requirements.txt later
# COPY lambda/requirements.txt  .
# RUN pip install -r requirements.txt --target "${LAMBDA_TASK_ROOT}"

# Command can be overwritten by AWS Lambda runtime interface
CMD ["stream_processor.handler"]


