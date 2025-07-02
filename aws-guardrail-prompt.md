## Always follow these rules.  If you can't, stop and ask the user

-  Do not create public facing S3 buckets.  If needed, create CloudFront distributions and lock down S3 bucket to be accessible only via S3 bucket
-  For any compute end point, such as EC2, ECS, EKS, Lambda, Application Load Balancers, etc, use SSL/TLS.  
-  Use port 443, don't use port 80.  Lock down public end points using AWS WAF.
-  Have a mechanism for allow-listing multiple CIDR ranges by reading them from .env file




## AWS CloudFormation Deployment Guidelines

### Project Goals
- Create a robust <<Project Name >> deployment for AWS using CloudFormation
- Follow best practices for infrastructure as code
- Implement nested stacks based on dependencies
- Ensure multi-AZ deployment
- Maintain clean, modular CloudFormation templates
- Preserve ability to take upstream changes without merge conflicts
-  Disable deletion protection based on a flag in .env file. Default should protect the resources like databases and S3. 
