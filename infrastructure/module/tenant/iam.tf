module "iam_role" {
  source     = "terraform-aws-modules/iam/aws//modules/iam-role"
  depends_on = [module.iam_oidc_provider]

  name        = "${local.name}-actions"
  description = "Role for GitHub Actions to deploy DevOps-project-02"

  enable_github_oidc = true

  oidc_wildcard_subjects = [
    "repo:yaswanthsai257/devops:*",
    "repo:Henildonda01/DevOps-project-02:*"
  ]

  policies = {
    AdministratorAccess = "arn:aws:iam::aws:policy/AdministratorAccess"
  }

  tags = local.common_tags
}
