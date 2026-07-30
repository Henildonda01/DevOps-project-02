module "iam_role" {
  source     = "terraform-aws-modules/iam/aws//modules/iam-role"
  depends_on = [module.iam_oidc_provider]

  name        = "${local.name}-actions"
  description = "Role for GitHub Actions to deploy DevOps-project-02"

  enable_github_oidc = true

  oidc_wildcard_subjects = [
    "repo:Henildonda01/DevOps-project-02:*",
    "repo:Henildonda01@262137270/DevOps-project-02@1315757718:*"
  ]

  policies = {
    AdministratorAccess = "arn:aws:iam::aws:policy/AdministratorAccess"
  }

  tags = local.common_tags
}
