#!/bin/bash
set -euo pipefail

NAMESPACE="ingress-nginx"
SERVICE="ingress-nginx-controller"

echo "=========================================================="
echo "  SIMULACIÓN DE ATAQUE / TRÁFICO ANÓMALO (TP12C)"
echo "=========================================================="

if ! kubectl get namespace "$NAMESPACE" >/dev/null 2>&1; then
    echo "No se puede ejecutar la simulación."
    echo "No existe el namespace $NAMESPACE."
    exit 0
fi

if ! kubectl get service "$SERVICE" -n "$NAMESPACE" >/dev/null 2>&1; then
    echo "No se puede ejecutar la simulación."
    echo "No existe el servicio $SERVICE."
    echo "Se requiere desplegar NGINX Ingress Controller."
    exit 0
fi

NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
INGRESS_PORT=$(kubectl get svc -n "$NAMESPACE" "$SERVICE" -o jsonpath='{.spec.ports[?(@.name=="http")].nodePort}')
URL="http://$NODE_IP:$INGRESS_PORT"

echo "Objetivo: $URL"

echo "[1/2] Generando solicitudes a rutas inexistentes..."
for i in {1..50}; do
    curl -s -o /dev/null -w "%{http_code}\n" \
      -H "Host: devops-portfolio.local" "$URL/admin-admin-$i" || true
done

echo "[2/2] Simulando intentos de login..."
for i in {1..30}; do
    curl -s -o /dev/null -w "%{http_code}\n" \
      -X POST -H "Host: devops-portfolio.local" \
      "$URL/api/v1/login" -d '{"user":"admin","pass":"wrong"}' || true
done

echo "=== Simulación completada ==="
echo "Verifica las alertas en Prometheus."
