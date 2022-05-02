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

    {:ok, results} = response.body() |> JSON.decode()

    for posting <- results["data"] do
      IO.inspect(posting["id"])
      IO.inspect(posting["categories"]["team"])
      IO.inspect(posting["text"])
      # IO.inspect(posting["content"]["descriptionHtml"])
    end

    # File.write("../postings.json",response.body(), [:binary])

  end
end
