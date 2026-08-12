import requests

# No API key - testing without one first
url = "https://api.census.gov/data/2022/acs/acs5?get=NAME,B01003_001E&for=tract:*&in=state:17+county:031"

response = requests.get(url)
print(response.status_code)
print(response.text[:500])