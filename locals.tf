locals {
    azs = ["${var.region}a", "${var.region}b"]
    prefix = substr("${replace(basename(path.cwd), "_", "-")}", 0, 6)
    ami_id = data.aws_ami.amzlinx2.id
    tag_spec_resources = ["instance", "volume", "network-interface"]
    user_data = <<EOF
#!/bin/bash
systemctl disable --now docker
amazon-linux-extras disable docker # included in ecs
amazon-linux-extras install -y ecs
echo ECS_CLUSTER=${var.ecs_cluster_name} >> /etc/ecs/ecs.config # If commented it will join the default cluster
systemctl enable --now --no-block ecs.service
EOF
}