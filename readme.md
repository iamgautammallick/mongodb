☁️💻 EC2 🏗️ with 🏗️Terraform

This 🏗️Terraform project provisions ☁️AWS infrastructure including a 🌐Virtual Private Cloud (VPC), 🛤️subnets, 🔒security groups, and two EC2 🖥️ instances named control-plane and worker-node1. The 🖥️ instances are configured with 🔒SSH and 🌍HTTP access enabled, and an SSH 🔑 key pair is generated and stored locally for 🔒 secure remote access.

🌟 Features

☁️AWS EC2 🖥️ Instances: Creates two t2.medium instances named control-plane and worker-node1.

🔑SSH Key Pair: Generates a secure SSH key pair for accessing the EC2 🖥️ instances.

🌐VPC and 🛤️Subnet: Creates a new VPC with a public 🛤️ subnet.

🔒Security Groups: Configures security groups to allow inbound 🔒SSH and 🌍HTTP traffic.

📋 Prerequisites

🏗️Terraform v1.0.0 or higher: Install 🏗️Terraform by following the instructions here.

☁️AWS Account: Ensure you have ☁️AWS credentials configured. You can set them up using the AWS CLI.

IAM 👤 User with EC2 Access: Make sure the IAM 👤 user has permissions to create EC2 🖥️ instances, 🌐VPCs, 🛤️subnets, 🔒security groups, and 🔑key pairs.

🛠️ Usage

1. 🌀 Clone the Repository

2. ⚙️ Initialize 🏗️Terraform

Run the following command to initialize 🏗️Terraform, which will download necessary provider plugins:

3. 👀 Review the Plan

To see the list of resources that will be created, execute:

4. 🚀 Apply the Configuration

To create the resources, run:

🏗️Terraform will prompt you to confirm the action. Type yes to proceed.

5. 🔑 Accessing the EC2 🖥️ Instances

After the resources are created, you can use the generated private 🔑 key (t2_medium.pem) to SSH into the 🖥️ instances.

Replace <CONTROL_PLANE_PUBLIC_IP> with the public IP address provided by the 🏗️Terraform output.

6. 🗑️ Destroy the Infrastructure

If you no longer need the resources, you can destroy them to avoid incurring costs:

Confirm the action by typing yes when prompted.

🏗️ Resources Created

🌐VPC: A new VPC with CIDR block 10.0.0.0/16.

🛤️Subnet: A public 🛤️ subnet with CIDR block 10.0.1.0/24.

🌍Internet Gateway: To enable internet access for resources within the 🌐VPC.

🛤️Route Table: A 🛤️ route table associated with the public 🛤️ subnet.

🔒Security Groups:

🔒SSH Access: Allows inbound SSH traffic (port 22).

🌍HTTP Access: Allows inbound HTTP traffic (port 80).

EC2 🖥️ Instances:

control-plane: t2.medium instance.

worker-node1: t2.medium instance.

🔑SSH Key Pair: Generated SSH key pair (t2_medium.pem).

⚠️ Important Notes

🔒Security: The 🔒security group allows inbound SSH and 🌍HTTP access from any IP (0.0.0.0/0). For better security, restrict access to specific IP addresses.

🔑 Key File Security: Ensure that the private key (t2_medium.pem) is stored securely and has appropriate file permissions (chmod 400).

💰 AWS Costs: Be mindful of ☁️AWS costs when running EC2 🖥️ instances. Destroy the resources (terraform destroy) when they are no longer needed.

📜 License

This project is licensed under the MIT License - see the LICENSE file for details.

🤝 Contributing

Contributions are welcome! Please open an issue or submit a pull request for improvements or bug fixes.

📞 Contact

If you have any questions, feel free to reach out to the repository owner.
