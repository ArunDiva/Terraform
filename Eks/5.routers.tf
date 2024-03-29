resource "aws_route_table" "pub-r" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "pub-route-table"
  }
}

resource "aws_route_table" "pvt-r" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
    #gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "pvt-route-table"
  }
}


resource "aws_route_table_association" "pub-a" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.pub-r.id
}


resource "aws_route_table_association" "pvt-a" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.pvt-r.id
}