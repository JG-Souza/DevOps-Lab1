# Cria uma VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "lab1-vpc"
  }
}

# Cria duas subnets públicas
resource "aws_subnet" "pub1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true # Faz com que a subnet receba um IP público

  tags = {
    Name = "lab1-subnet-pub1"
  }
}

resource "aws_subnet" "pub2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = true # Faz com que a subnet receba um IP público

  tags = {
    Name = "lab1-subnet-pub2"
  }
}

# Cria duas subnets privadas
resource "aws_subnet" "priv1" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.3.0/24"

  tags = {
    Name = "lab1-subnet-priv1"
  }
}

resource "aws_subnet" "priv2" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.4.0/24"

  tags = {
    Name = "lab1-subnet-priv2"
  }
}

# Cria o Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main"
  }
}

# Garante um IP público estático para o NAT Gateway
resource "aws_eip" "nat_eip" {
  domain = "vpc"

  tags = {
    Name = "main-nat-gateway-eip"
  }
}

# Cria o NAT Gateway para as subnets privadas
resource "aws_nat_gateway" "ngw" {
  allocation_id = aws_eip.nat_eip.id # Vincula o NAT Gateway a um EIP
  subnet_id     = aws_subnet.pub1.id

  tags = {
    Name = "main-nat-gateway"
  }

  depends_on = [aws_internet_gateway.igw]
}

# Cria a Tabela de Rotas para as subnets Públicas
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "lab1-trt-public"
  }
}

# Cria a tabela de rotas para as subnets Privadas
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "lab1-trt-private"
  }
}

# Configuração de rota da subnet pública
resource "aws_route" "public_internet_access" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0" # Significa qualquer IP que não esteja na VPC (qualquer lugar na internet)
  gateway_id             = aws_internet_gateway.igw.id
}

# Configuração de rota da subnet privada
resource "aws_route" "private_internet_access" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0" # Significa qualquer IP que não esteja na VPC (qualquer lugar na internet)
  nat_gateway_id         = aws_nat_gateway.ngw.id
}

# Associa as subnets públicas à tabela de rotas pública
resource "aws_route_table_association" "pub_assoc_1" {
  subnet_id      = aws_subnet.pub1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "pub_assoc_2" {
  subnet_id      = aws_subnet.pub2.id
  route_table_id = aws_route_table.public.id
}

# Associa as subnets privadas à tabela de rotas privada
resource "aws_route_table_association" "priv_assoc_1" {
  subnet_id      = aws_subnet.priv1.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "priv_assoc_2" {
  subnet_id      = aws_subnet.priv2.id
  route_table_id = aws_route_table.private.id
}