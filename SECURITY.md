# Security

## Reporting a vulnerability

If you discover a potential security issue in this project, we ask that you notify AWS/Amazon Security via the [vulnerability reporting page](http://aws.amazon.com/security/vulnerability-reporting/). Please do **not** create a public issue.

## Production deployment guidance

The Terraform configuration in this repository is a **sample pattern** intended to demonstrate how to automate cross-account S3 data distribution using [AWS DataSync](https://docs.aws.amazon.com/datasync/latest/userguide/what-is-datasync.html) Enhanced mode. Before deploying to a production environment, review and apply the hardening recommendations below.

### Amazon S3 bucket security configuration

Securing both the source and destination Amazon S3 buckets is the customer's responsibility. At a minimum, enable the following on all buckets:

- **Block Public Access** — enable all four Block Public Access settings at the bucket level. See [Blocking public access to your Amazon S3 storage](https://docs.aws.amazon.com/AmazonS3/latest/userguide/access-control-block-public-access.html).
- **Default encryption** — enable server-side encryption with Amazon S3 managed keys (SSE-S3) or AWS Key Management Service keys (SSE-KMS). See [Protecting data with server-side encryption](https://docs.aws.amazon.com/AmazonS3/latest/userguide/serv-side-encryption.html).
- **Versioning** — enable versioning to protect against accidental overwrites and deletions. See [Using versioning in Amazon S3 buckets](https://docs.aws.amazon.com/AmazonS3/latest/userguide/Versioning.html).
- **Access logging** — enable server access logging or AWS CloudTrail data events for audit purposes. See [Logging requests using server access logging](https://docs.aws.amazon.com/AmazonS3/latest/userguide/ServerLogs.html).
- **Lifecycle policies** — configure lifecycle rules appropriate for your data retention requirements.

### S3 Object Ownership

Set Object Ownership to `BucketOwnerEnforced` on all destination buckets. This ensures the spoke account automatically owns all objects written by the hub's DataSync role and disables ACLs entirely. See [Controlling ownership of objects](https://docs.aws.amazon.com/AmazonS3/latest/userguide/about-object-ownership.html).

### IAM roles

- The DataSync service role uses `aws:SourceAccount` conditions in its trust policy to prevent confused deputy attacks.
- All IAM policies are scoped to specific bucket ARNs — no wildcard resource ARNs are used.
- For production, consider adding `aws:SourceArn` conditions to further restrict the trust policy.

### SNS topic

- The SNS topic policy restricts publishing to the specific EventBridge rule ARN.
- For production, consider enabling SSE on the SNS topic using an AWS KMS key.

### Terraform state

- Store Terraform state in an S3 bucket with versioning, encryption, and DynamoDB locking enabled.
- Restrict access to the state bucket to authorized CI/CD pipelines and operators.

## Accepted security considerations

### 1. Wildcard suffixes in IAM policy Resource ARNs

The IAM policies use `/*` suffixes on S3 bucket ARNs to grant object-level access. This is required for DataSync to read source objects and write destination objects. All wildcards are scoped to specific bucket ARNs.

**Risk:** Low. Wildcards are constrained to named resources and are required by the S3 API for object-level operations.

### 2. Cross-account trust relationships

The hub account's DataSync role is granted write access to spoke destination buckets via bucket policies. Each spoke bucket policy explicitly names the hub DataSync role ARN — no account-wide trust is granted.

**Risk:** Low. Access is scoped to a single IAM role with least-privilege permissions.

### 3. SNS email subscriptions

Email subscriptions require manual confirmation. Unconfirmed subscriptions do not receive notifications. For production, consider using HTTPS endpoints, AWS Chatbot, or PagerDuty integrations instead of email.

**Risk:** Low. Standard SNS subscription confirmation workflow.
