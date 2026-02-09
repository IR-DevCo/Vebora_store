from xui_client import XUIClient

# Initialize 3x-ui client
xui = XUIClient()

def get_user_usage(uuid: str) -> dict:
    """
    Get the usage statistics of a specific user by UUID
    """
    try:
        data = xui.get_usage(uuid)
        # Example return: { "up": 123456, "down": 654321, "total": 777777 }
        usage_info = {
            "upload_bytes": data.get("up", 0),
            "download_bytes": data.get("down", 0),
            "total_bytes": data.get("total", 0)
        }
        return usage_info
    except Exception as e:
        raise Exception(f"Failed to get usage for {uuid}: {e}")

def get_all_users_usage() -> list:
    """
    Get usage statistics for all clients of the inbound
    """
    try:
        clients = xui.get_clients()
        usage_list = []
        for client in clients:
            uuid = client.get("uuid")
            if not uuid:
                continue
            usage = get_user_usage(uuid)
            usage_list.append({
                "email": client.get("email"),
                "uuid": uuid,
                "usage": usage
            })
        return usage_list
    except Exception as e:
        raise Exception(f"Failed to get usage for all clients: {e}")
