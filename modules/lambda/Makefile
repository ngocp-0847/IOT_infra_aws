# Makefile cho Lambda functions

.PHONY: build clean help

# Default target
all: build

# Build tất cả Lambda functions
build:
	@echo "🚀 Building Lambda functions..."
	@./build.sh

# Xóa các file build
clean:
	@echo "🧹 Cleaning up build artifacts..."
	@rm -f *.zip
	@rm -rf build/
	@echo "✅ Cleanup completed"

# Build một function cụ thể
build-query:
	@echo "📦 Building query_handler only..."
	@cd lambda && zip -r ../query_handler.zip query_handler.py

build-stream:
	@echo "📦 Building stream_processor only..."
	@cd lambda && zip -r ../stream_processor.zip stream_processor.py

# Hiển thị thông tin các file build
info:
	@echo "📁 Lambda deployment packages:"
	@ls -la *.zip 2>/dev/null || echo "Chưa có file nào được build"

# Hiển thị help
help:
	@echo "🛠️  Lambda Build Commands:"
	@echo ""
	@echo "  make build        - Build tất cả Lambda functions"
	@echo "  make clean        - Xóa các file build"
	@echo "  make build-query  - Build chỉ query_handler"
	@echo "  make build-stream - Build chỉ stream_processor"
	@echo "  make info         - Hiển thị thông tin các file build"
	@echo "  make help         - Hiển thị help này"
	@echo ""
	@echo "📝 Note: Các file .zip sẽ được tạo trong thư mục hiện tại"