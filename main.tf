resource "aws_vpc" "main" {
  cidr_block       = var.cidr_block
  enable_dns_hostnames = true  #ec2-54-123-45-67.compute-1.amazonaws.com users can able to ssh to the instance using the public DNS
  tags = merge(
    var.common_tags,
    var.vpc_tags,
    {
        Name = local.resource_name
    }
  )
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id  

  tags = merge(
    var.common_tags,
    var.igw_tags,
    {
        Name = local.resource_name
    }
  )
}


resource "aws_subnet" "public" {
  count = length(local.availability_zones)
  vpc_id     = aws_vpc.main.id
  cidr_block = var.public_cidr_block[count.index]
  availability_zone = local.availability_zones[count.index]
  map_public_ip_on_launch = true
  tags = merge(
	var.common_tags,
	var.public_subnet_tags,
	{
		Name = "${var.project_name}-${var.environment}-public-${local.availability_zones[count.index]}"
	}
  )
}

resource "aws_subnet" "private" {
  count = length(local.availability_zones)
  vpc_id     = aws_vpc.main.id
  cidr_block = var.private_cidr_block[count.index]
  availability_zone = local.availability_zones[count.index]
  tags = merge(
    var.common_tags,
    var.private_subnet_tags,
    {
        Name = "${var.project_name}-${var.environment}-private-${local.availability_zones[count.index]}"
    }
  )
}

resource "aws_subnet" "database" {
  count = length(local.availability_zones)
  vpc_id     = aws_vpc.main.id
  cidr_block = var.database_cidr_block[count.index]
  availability_zone = local.availability_zones[count.index]
  tags = merge(
    var.common_tags,
    var.database_subnet_tags,
    {
        Name = "${var.project_name}-${var.environment}-database-${local.availability_zones[count.index]}"
    }
  )
}

# # Database services (like RDS/Aurora) require at least 2 subnets across different Availability Zones (AZs).
# # Grouping database subnets ensures that AWS can automatically failover to another subnet in a different AZ if one AZ goes down.
# # If AZ-1 fails, AWS RDS/Aurora can shift traffic to a database in AZ-2 without downtime.
resource "aws_db_subnet_group" "main" {
  name       = local.resource_name
  subnet_ids = aws_subnet.database[*].id

  tags = merge(
    var.common_tags,
    var.db_subnet_tags,
    {
        Name = local.resource_name
    }
  )
}

resource "aws_eip" "eip" {
  domain   = "vpc"
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.eip.id
  subnet_id     = aws_subnet.public[0].id

  tags = merge(
    var.common_tags,
    {
        Name = "${var.project_name}-${var.environment}"
    }
  )
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags =merge(
    var.common_tags,
    var.public_route_table_tags,
    {
        Name = "${var.project_name}-${var.environment}-public"
    }
  )
}
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    var.common_tags,
    var.private_route_table_tags,
    {
        Name = "${var.project_name}-${var.environment}-private"
    }
  )
}

resource "aws_route_table" "database" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    var.common_tags,
    var.database_route_table_tags,
    {
        Name = "${var.project_name}-${var.environment}-database"
    }
  )
}

resource "aws_route" "public" {
  route_table_id            = aws_route_table.public.id
  destination_cidr_block    = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.main.id
}

resource "aws_route" "private" {
  route_table_id            = aws_route_table.private.id
  destination_cidr_block    = "0.0.0.0/0"
  nat_gateway_id = aws_nat_gateway.nat.id
}

resource "aws_route" "database" {
  route_table_id            = aws_route_table.database.id
  destination_cidr_block    = "0.0.0.0/0"
  nat_gateway_id = aws_nat_gateway.nat.id
}

resource "aws_route_table_association" "public" {
  count = length(var.public_cidr_block)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count = length(var.private_cidr_block)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "database" {
  count = length(var.database_cidr_block)
  subnet_id      = aws_subnet.database[count.index].id
  route_table_id = aws_route_table.database.id
}