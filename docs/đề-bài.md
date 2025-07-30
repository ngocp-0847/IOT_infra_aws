Đề bài 1: Nền tảng Phân tích Dữ liệu IoT
Ý tưởng: Xây dựng một nền tảng nhận dữ liệu từ hàng triệu thiết bị cảm biến (nhiệt độ, độ ẩm), xử lý và cung cấp API cho các ứng dụng khác truy vấn.
Yêu cầu:
Chức năng: Hệ thống phải có khả năng tiếp nhận (ingest) một lượng lớn message mỗi giây. Dữ liệu thô phải được lưu trữ, sau đó được xử lý (ví dụ: tính giá trị trung bình theo giờ) và lưu vào một cơ sở dữ liệu có thể truy vấn nhanh.
Kỹ thuật: Cần một giải pháp có khả năng xử lý luồng dữ liệu thời gian thực (real-time stream processing). Dữ liệu thô cần được lưu trữ một cách bền bỉ và chi phí thấp.