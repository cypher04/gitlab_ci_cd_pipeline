variable "tenant_id" {
  description = "The Azure AD tenant ID."
  type        = string
}

variable "gitlab_token" {
  description = "The GitLab personal access token."
  type        = string
}

variable "gitlab_base_url" {
  description = "The GitLab instance URL."
  type        = string
}

variable "gitlab_namespace" {
  description = "The GitLab namespace (group or user) where the project will be created."
  type        = string
}

variable "gitlab_project_name" {
  description = "The name of the GitLab project to be created."
  type        = string
}

variable "default_branch" {
  description = "The default branch for the GitLab project."
  type        = string
  default     = "main"
}

variable "subscription_id" {
  description = "The Azure subscription ID."
  type        = string
}

variable "vm_password" {
  description = "The password for the virtual machine."
  type        = string
}