// create gitlab project and configure CI/CD pipeline
data "gitlab_project" "gitlab_project" {
  path_with_namespace = "${var.gitlab_namespace}/${var.gitlab_project_name}"
}

// create project environment for the default branch
resource "gitlab_project_environment" "default_branch_env" {
  project = data.gitlab_project.gitlab_project.id
  name    = var.default_branch
  external_url = "https://gitlab.com/${var.gitlab_namespace}/${var.gitlab_project_name}/-/environments/${var.default_branch}"
}

// create branch protection rule for the default branch
resource "gitlab_branch_protection" "default_branch_protection" {
  project = data.gitlab_project.gitlab_project.id
  branch  = var.default_branch
  allowed_to_push = [
    {
        access_level = "maintainer"
    }
  ]
  allowed_to_merge = [
    {
        access_level = "developer"
    }
  ]
}
