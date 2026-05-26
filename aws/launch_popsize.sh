#!/bin/bash
# launch_popsize.sh
# PopSize — Tamaño Efectivo SH
# Patrón: EastWestDM/GoodPractice.md

set -euo pipefail

source "$(dirname "$0")/config.env"

# Override key path (copiada a PopSize/aws)
KEY_PATH="$(dirname "$0")/sima-key-2026.pem"

INSTANCE_TYPE="c5.2xlarge"   # 8 vCPU, 16GB — suficiente para ANGSD + ROHan
VOLUME_SIZE=150               # BAMs pequeños + hg38 + outputs
JOB_NAME="popsize-sima-Ne"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

echo "================================================="
echo "  PopSize — Ne efectivo Sima de los Huesos"
echo "================================================="
echo "  Instancia : ${INSTANCE_TYPE} (Spot)"
echo "  EBS       : ${VOLUME_SIZE} GB gp3"
echo "  Región    : ${AWS_REGION}"
echo "  Bucket    : s3://${S3_BUCKET}"
echo "  Tiempo    : ~1.5-2h estimado"
echo "  Coste     : ~€0.15-0.20 total"
echo "================================================="

# Verificar credenciales
if ! aws sts get-caller-identity &>/dev/null; then
    echo "❌ ERROR: Credenciales AWS no configuradas"
    exit 1
fi

# Subir user_data a S3 (evita límite 16KB de user_data directo)
echo "📦 Subiendo pipeline a S3..."
aws s3 cp "$(dirname "$0")/../scripts/user_data_popsize.sh" \
    s3://${S3_BUCKET}/popsize/scripts/user_data_popsize.sh \
    --region ${AWS_REGION}
echo "  ✓ Pipeline en S3"

# Bootstrap mínimo — descarga el script real desde S3
BOOTSTRAP=$(cat << BOOT
#!/bin/bash
aws s3 cp s3://${S3_BUCKET}/popsize/scripts/user_data_popsize.sh /tmp/run.sh --region ${AWS_REGION}
chmod +x /tmp/run.sh
bash /tmp/run.sh
BOOT
)

USER_DATA_B64=$(echo "$BOOTSTRAP" | base64 -w 0)

# Launch spec
cat > /tmp/launch_spec_popsize.json << SPEC
{
    "ImageId": "${UBUNTU_AMI}",
    "InstanceType": "${INSTANCE_TYPE}",
    "KeyName": "${KEY_NAME}",
    "SecurityGroupIds": ["${SG_ID}"],
    "IamInstanceProfile": {"Name": "${IAM_INSTANCE_PROFILE}"},
    "BlockDeviceMappings": [{
        "DeviceName": "/dev/sda1",
        "Ebs": {
            "VolumeSize": ${VOLUME_SIZE},
            "VolumeType": "gp3",
            "Throughput": 250,
            "DeleteOnTermination": true
        }
    }],
    "UserData": "${USER_DATA_B64}"
}
SPEC

echo "📡 Solicitando Spot Instance..."
SPOT_RESPONSE=$(aws ec2 request-spot-instances \
    --instance-count 1 \
    --type "one-time" \
    --instance-interruption-behavior "terminate" \
    --region "${AWS_REGION}" \
    --launch-specification file:///tmp/launch_spec_popsize.json)

SPOT_ID=$(echo "$SPOT_RESPONSE" | \
    python3 -c "import sys,json; print(json.load(sys.stdin)['SpotInstanceRequests'][0]['SpotInstanceRequestId'])")

echo "✅ Spot Request: ${SPOT_ID}"
echo "$SPOT_ID" > "$(dirname "$0")/instance_id_popsize.txt"

echo "⏳ Esperando asignación (~30s)..."
sleep 30

INSTANCE_ID=$(aws ec2 describe-spot-instance-requests \
    --spot-instance-request-ids "$SPOT_ID" \
    --region "${AWS_REGION}" \
    --query 'SpotInstanceRequests[0].InstanceId' \
    --output text 2>/dev/null)

if [ "$INSTANCE_ID" != "None" ] && [ -n "$INSTANCE_ID" ]; then
    aws ec2 create-tags \
        --resources "$INSTANCE_ID" \
        --tags \
            Key=Name,Value=${JOB_NAME} \
            Key=Project,Value=PopSize \
            Key=Date,Value=$(date +%Y-%m-%d) \
        --region "${AWS_REGION}"

    echo "$INSTANCE_ID" >> "$(dirname "$0")/instance_id_popsize.txt"

    sleep 20
    IP=$(aws ec2 describe-instances \
        --instance-ids "$INSTANCE_ID" \
        --region "${AWS_REGION}" \
        --query 'Reservations[0].Instances[0].PublicIpAddress' \
        --output text)
    echo "$IP" > "$(dirname "$0")/ip_popsize.txt"

    echo ""
    echo "================================================="
    echo "  INSTANCIA ACTIVA"
    echo "  ID : ${INSTANCE_ID}"
    echo "  IP : ${IP}"
    echo "  SSH: ssh -i ${KEY_PATH} ubuntu@${IP}"
    echo "================================================="
fi

echo ""
echo "📊 MONITOREO:"
echo "  # Logs en tiempo real:"
echo "  watch -n 60 'aws s3 ls s3://${S3_BUCKET}/popsize/logs/ --region ${AWS_REGION} | tail -3'"
echo ""
echo "  # Resultados cuando termine:"
echo "  aws s3 sync s3://${S3_BUCKET}/popsize/results_${TIMESTAMP}/ ~/PopSize/results/ --region ${AWS_REGION}"

rm -f /tmp/launch_spec_popsize.json
