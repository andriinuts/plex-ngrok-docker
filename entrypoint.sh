#!/bin/sh -e

if [ -n "$@" ]; then
  exec "$@"
fi

# Legacy compatible:
if [ -z "$NGROK_PORT" ]; then
  if [ -n "$HTTPS_PORT" ]; then
    NGROK_PORT="$HTTPS_PORT"
  elif [ -n "$HTTPS_PORT" ]; then
    NGROK_PORT="$HTTP_PORT"
  elif [ -n "$APP_PORT" ]; then
    NGROK_PORT="$APP_PORT"
  fi
fi


ARGS="ngrok"

# Set the protocol.
if [ "$NGROK_PROTOCOL" = "TCP" ]; then
  ARGS="$ARGS tcp"
else
  ARGS="$ARGS http"
  NGROK_PORT="${NGROK_PORT:-80}"
fi

# Set the TLS binding flag
if [ -n "$NGROK_BINDTLS" ]; then
  ARGS="$ARGS -bind-tls=$NGROK_BINDTLS "
fi

# Set the authorization token.
if [ -n "$NGROK_AUTH" ]; then
  ARGS="$ARGS -authtoken=$NGROK_AUTH "
fi

# Set the subdomain or hostname, depending on which is set
if [ -n "$NGROK_HOSTNAME" ] && [ -n "$NGROK_AUTH" ]; then
  ARGS="$ARGS -hostname=$NGROK_HOSTNAME "
elif [ -n "$NGROK_SUBDOMAIN" ] && [ -n "$NGROK_AUTH" ]; then
  ARGS="$ARGS -subdomain=$NGROK_SUBDOMAIN "
elif [ -n "$NGROK_HOSTNAME" ] || [ -n "$NGROK_SUBDOMAIN" ]; then
  if [ -z "$NGROK_AUTH" ]; then
    echo "You must specify an authentication token after registering at https://ngrok.com to use custom domains."
    exit 1
  fi
fi

# Set a custom region
if [ -n "$NGROK_REGION" ]; then
  ARGS="$ARGS -region=$NGROK_REGION "
fi

if [ -n "$NGROK_HEADER" ]; then
  ARGS="$ARGS -host-header=$NGROK_HEADER "
fi

if [ -n "$NGROK_USERNAME" ] && [ -n "$NGROK_PASSWORD" ] && [ -n "$NGROK_AUTH" ]; then
  ARGS="$ARGS -auth=$NGROK_USERNAME:$NGROK_PASSWORD "
elif [ -n "$NGROK_USERNAME" ] || [ -n "$NGROK_PASSWORD" ]; then
  if [ -z "$NGROK_AUTH" ]; then
    echo "You must specify a username, password, and Ngrok authentication token to use the custom HTTP authentication."
    echo "Sign up for an authentication token at https://ngrok.com"
    exit 1
  fi
fi

if [ -n "$NGROK_DEBUG" ]; then
    ARGS="$ARGS -log stdout"
fi

# Set the port.
if [ -z "$NGROK_PORT" ]; then
  echo "You must specify a NGROK_PORT to expose."
  exit 1
fi
ARGS="$ARGS `echo $NGROK_PORT | sed 's|^tcp://||'`"

set -x
exec $ARGS

NGROK_URL = curl --silent --show-error http://127.0.0.1:4040/api/tunnels | sed -nE 's/.*public_url":"https:..([^"]*).*/\1/p'
python3 plexurl.py $NGROK_URL $PLEX_USER $PLEX_PWORD $PLEX_SERVER
