#!/bin/bash

set -e  # Para o script parar em caso de erro

echo "Verificando instalação do Apache Spark em modo cluster..."

echo "Verificando Java..."
java -version || { echo "Java não está instalado corretamente."; exit 1; }

echo "Verificando Scala..."
scala -version || { echo "Scala não está instalado corretamente."; exit 1; }

echo "Verificando SPARK_HOME..."
if [ -z "$SPARK_HOME" ]; then
    echo "SPARK_HOME não está definido."
    exit 1
else
    echo "SPARK_HOME = $SPARK_HOME"
fi

echo "Verificando inclusão do Spark no PATH..."
if [[ ":$PATH:" == *":$SPARK_HOME/bin:"* && ":$PATH:" == *":$SPARK_HOME/sbin:"* ]]; then
    echo "PATH contém os diretórios do Spark."
else
    echo "PATH está incorreto. Verifique sua configuração."
    exit 1
fi

echo "Verificando PYSPARK_PYTHON..."
if [ -z "$PYSPARK_PYTHON" ]; then
    echo "PYSPARK_PYTHON não está definido."
else
    echo "PYSPARK_PYTHON = $PYSPARK_PYTHON"
fi

echo "Verificando diretório do Spark em /opt..."
if [ ! -d "/opt/spark" ]; then
    echo "/opt/spark não encontrado."
    exit 1
fi

echo "Verificando pyspark no PATH..."
if ! command -v pyspark > /dev/null; then
    echo "pyspark não encontrado no PATH."
    exit 1
fi

echo "Iniciando Spark Master..."
$SPARK_HOME/sbin/stop-master.sh > /dev/null 2>&1 || true
$SPARK_HOME/sbin/start-master.sh --host localhost

echo "Iniciando Spark Worker..."
$SPARK_HOME/sbin/stop-worker.sh > /dev/null 2>&1 || true
$SPARK_HOME/sbin/start-worker.sh --host localhost spark://localhost:7077



echo "Aguardando inicialização..."
sleep 3

echo "Criando teste_spark.py..."
cat << EOF > teste_spark.py
from pyspark.sql import SparkSession

spark = (
    SparkSession.builder
    .appName("DeltaExample")
    .config("spark.sql.extensions", "io.delta.sql.DeltaSparkSessionExtension")
    .config("spark.sql.catalog.spark_catalog", "org.apache.spark.sql.delta.catalog.DeltaCatalog")
    .getOrCreate()
)

df = spark.range(5)
df.show()
df.write.format("delta").save("./saida_delta")

EOF

echo "Executando spark-submit no modo cluster..."

spark-submit --master spark://localhost:7077\
  --packages io.delta:delta-spark_2.12:3.1.0 \
  --conf "spark.sql.extensions=io.delta.sql.DeltaSparkSessionExtension" \
  --conf "spark.sql.catalog.spark_catalog=org.apache.spark.sql.delta.catalog.DeltaCatalog" \
  teste_spark.py

echo "Finalizado. Verifique a interface web em http://localhost:8080"
