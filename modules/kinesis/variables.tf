variable "stream_name" {
  description = "Tên Kinesis Data Stream"
  type        = string
}

variable "shard_count" {
  description = "Số lượng shards"
  type        = number
}

variable "environment" {
  description = "Môi trường triển khai"
  type        = string
}

variable "project_name" {
  description = "Tên project"
  type        = string
}

variable "tags" {
  description = "Tags chung"
  type        = map(string)
  default     = {}
} 