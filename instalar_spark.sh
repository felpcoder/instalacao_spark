#!/bin/bash

set -e  # Para o script se qualquer comando falhar, exceto onde lidamos manualmente

echo "Atualizando pacotes..."
sudo apt-get update

echo "Instalando dependências: JDK, Scala e Git..."
sudo apt install default-jdk scala git -y

echo "Baixando Apache Spark 3.5.5..."
wget https://dlcdn.apache.org/spark/spark-3.5.5/spark-3.5.5-bin-hadoop3.tgz

echo "Baixando arquivo de verificação SHA512..."
wget https://dlcdn.apache.org/spark/spark-3.5.5/spark-3.5.5-bin-hadoop3.tgz.sha512

echo "Verificando integridade com SHA512..."

if sha512sum -c spark-3.5.5-bin-hadoop3.tgz.sha512; then
    echo "Checksum OK. Continuando..."
else
    echo "Checksum falhou! Abortando instalação."
    exit 1
fi

tar xvf spark-3.5.5-bin-hadoop3.tgz

sudo mv spark-3.5.5-bin-hadoop3 /opt/spark

echo "Gravando Variáveis de Ambiente"
echo 'export SPARK_HOME=/opt/spark' >> ~/.bashrc
echo 'export PATH=$SPARK_HOME/bin:$SPARK_HOME/sbin:$PATH' >> ~/.bashrc
echo 'export PYSPARK_PYTHON=/usr/bin/python3' >> ~/.bashrc

source ~/.bashrc

echo "Instalação finalizada, rode /opt/spark/bin/spark-shell --version para verificar instalação!"

