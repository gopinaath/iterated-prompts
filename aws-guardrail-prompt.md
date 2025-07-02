## Always follow these rules.  If you can't, stop and ask the user

-  Do not create public facing S3 buckets.  If needed, create CloudFront distributions and lock down S3 bucket to be accessible only via S3 bucket
-  For any compute end point, such as EC2, ECS, EKS, Lambda, Application Load Balancers, etc, use SSL/TLS.  
-  Use port 443, don't use port 80.  Lock down public end points using AWS WAF.
-  Have a mechanism for allow-listing multiple CIDR ranges by reading them from .env file
