import requests

api_key = "e2751cb55d5b31578ef632b0df6c7515d06139cb"

url = f"https://api.census.gov/data/2022/acs/acs5?get=NAME,B01003_001E&for=tract:*&in=state:17+county:031&key={api_key}"

response = requests.get(url)
print(response.status_code)
print(response.text[:500])