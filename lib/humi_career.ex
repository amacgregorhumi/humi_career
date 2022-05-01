defmodule HumiCareer do
  use HTTPoison.Base

  @lever_endpoint  "https://api.lever.co/v1/"

  def main() do
  end


  def retrieve_postings do
    credentials = "xj/YG/+Fs11bzbBPP8Sw40TldaqhV7CB3h8Yecup6kKueSOf:" |> Base.encode64()
    headers = ["Authorization": "Basic #{credentials}", "Accept": "application/json"]
    url = @lever_endpoint <> "postings"

    {:ok, response} = HTTPoison.get(url,headers, [])

    # result = response.body() |> JSON.decode()

    File.write("../postins.json",response.body(), [:binary])

  end
end
