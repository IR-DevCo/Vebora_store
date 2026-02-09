import requests
from requests.auth import HTTPBasicAuth
from config import XUI_URL, XUI_USER, XUI_PASS, XUI_INBOUND_ID

class XUIClient:
    def __init__(self):
        self.base_url = XUI_URL.rstrip("/")
        self.auth = HTTPBasicAuth(XUI_USER, XUI_PASS)
        self.inbound_id = XUI_INBOUND_ID
        self.token = None
        self.session = requests.Session()
        self.login()

    def login(self):
        """
        Login to 3x-ui panel (usually basic auth)
        """
        try:
            r = self.session.get(f"{self.base_url}/api/v1/inbounds/list", auth=self.auth)
            if r.status_code == 200:
                print("✅ Connected to 3x-ui successfully")
            else:
                raise Exception(f"Failed to connect to 3x-ui: {r.status_code} {r.text}")
        except Exception as e:
            print(f"❌ Error connecting to 3x-ui: {e}")
            raise e

    def add_client(self, email: str, uuid: str, remark: str = "") -> dict:
        """
        Add a new client to 3x-ui
        """
        url = f"{self.base_url}/api/v1/inbound/addClient"
        payload = {
            "id": self.inbound_id,
            "client": {
                "email": email,
                "uuid": uuid,
                "flow": "",
                "level": 0,
                "remark": remark
            }
        }
        r = self.session.post(url, json=payload, auth=self.auth)
        if r.status_code == 200:
            return r.json()
        else:
            raise Exception(f"Failed to add client: {r.status_code} {r.text}")

    def update_client(self, email: str, uuid: str, remark: str = "") -> dict:
        """
        Update existing client
        """
        url = f"{self.base_url}/api/v1/inbound/updateClient"
        payload = {
            "id": self.inbound_id,
            "client": {
                "email": email,
                "uuid": uuid,
                "flow": "",
                "level": 0,
                "remark": remark
            }
        }
        r = self.session.post(url, json=payload, auth=self.auth)
        if r.status_code == 200:
            return r.json()
        else:
            raise Exception(f"Failed to update client: {r.status_code} {r.text}")

    def get_clients(self) -> list:
        """
        Get all clients for this inbound
        """
        url = f"{self.base_url}/api/v1/inbounds/list"
        r = self.session.get(url, auth=self.auth)
        if r.status_code == 200:
            data = r.json()
            for inbound in data.get("inbounds", []):
                if inbound.get("id") == self.inbound_id:
                    return inbound.get("clients", [])
            return []
        else:
            raise Exception(f"Failed to fetch clients: {r.status_code} {r.text}")

    def get_usage(self, uuid: str) -> dict:
        """
        Get user usage statistics
        """
        url = f"{self.base_url}/api/v1/stat/{uuid}"
        r = self.session.get(url, auth=self.auth)
        if r.status_code == 200:
            return r.json()
        else:
            raise Exception(f"Failed to get usage for {uuid}: {r.status_code} {r.text}")
