#!/bin/bash

# Blue-Green Deployment Switch Script
# This script switches traffic between blue (basic UI) and green (enhanced UI) deployments

NAMESPACE="registration-app"
FRONTEND_LB="frontend-lb"

print_status() {
  echo "==================================================="
  echo "Current Frontend Service Configuration:"
  echo "==================================================="
  kubectl get service ${FRONTEND_LB} -n ${NAMESPACE} -o jsonpath='{.spec.selector}' | jq .
  echo ""
}

switch_to_blue() {
  echo "Switching traffic to BLUE deployment (Basic UI)..."
  kubectl patch service ${FRONTEND_LB} -n ${NAMESPACE} -p '{"spec":{"selector":{"deployment":"blue"}}}'
  echo "✓ Traffic switched to BLUE deployment"
  print_status
}

switch_to_green() {
  echo "Switching traffic to GREEN deployment (Enhanced UI)..."
  kubectl patch service ${FRONTEND_LB} -n ${NAMESPACE} -p '{"spec":{"selector":{"deployment":"green"}}}'
  echo "✓ Traffic switched to GREEN deployment"
  print_status
}

show_help() {
  echo "Blue-Green Deployment Switch Script"
  echo "Usage: $0 [command]"
  echo ""
  echo "Commands:"
  echo "  blue     - Switch traffic to blue deployment (basic UI)"
  echo "  green    - Switch traffic to green deployment (enhanced UI)"
  echo "  status   - Show current deployment status"
  echo "  help     - Show this help message"
  echo ""
}

# Main script logic
if [ $# -eq 0 ]; then
  show_help
  exit 1
fi

case "$1" in
  blue)
    switch_to_blue
    ;;
  green)
    switch_to_green
    ;;
  status)
    print_status
    ;;
  help|--help|-h)
    show_help
    ;;
  *)
    echo "Unknown command: $1"
    show_help
    exit 1
    ;;
esac
