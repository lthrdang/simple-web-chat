variable "project_id" {
  description = "The project ID to host the cluster in"
  type        = string
}

variable "region" {
  description = "The region to host the cluster in"
  type        = string
  default     = "us-central1"
}

variable "gke_num_nodes" {
  description = "Number of nodes in the GKE node pool"
  type        = number
  default     = 2
}

variable "machine_type" {
  description = "Machine type for GKE nodes"
  type        = string
  default     = "e2-medium"
}

variable "disk_size_gb" {
  description = "Disk size for GKE nodes in GB"
  type        = number
  default     = 50
}

variable "environment" {
  description = "Environment (dev/staging/prod)"
  type        = string
  default     = "dev"
} 