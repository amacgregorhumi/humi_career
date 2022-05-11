defmodule HumiCareer do
  use HTTPoison.Base

  @lever_endpoint  "https://api.lever.co/v1/"
  @webflow_endpoint  "https://api.webflow.com/"
  @web_collection_id  "6234a69edb0b4b06e73d515f"
  @team_collection_id "62334182fb264f451a431626"

  def main() do
    lever_postings = retrieve_postings("lever")
    web_flow_postings = retrieve_postings("webflow")

    #Webflow IDS
    webflow_ids =
      web_flow_postings["items"]
      |> Enum.map(fn a -> a["lever-uuid"] end)

    lever_postings
    |> Enum.each(&process_posting(&1, webflow_ids))
  end

  def update_item(posting) do
    IO.puts("To be Updated:")
    IO.inspect(posting[:lever_uuid])

    ## Find the webflow id from the list
    web_flow_postings = retrieve_postings("webflow")
    webflow_id = Enum.find(web_flow_postings["items"], fn (wfp) -> wfp["lever-uuid"] == posting[:lever_uuid] end)

    credentials = "f05f256dd66a6f010e3b025287dd9fe67fc8c6a7a9c30c37b39f5cb05c272ac7"
    headers = ["Authorization": "Bearer #{credentials}", "Content-Type": "application/json", "accept-version": "1.0.0"]
    url = @webflow_endpoint <> "collections/" <> @web_collection_id <> "/items/" <> webflow_id["_id"]

    teams = retrieve_teams()
    team = Enum.find(teams["items"], fn (t) -> t["name"] == posting[:team] end)

    IO.inspect(teams)

    body = Poison.encode!(
      %{ "fields" => %{
        "_archived" => false,
        "_draft" => false,
        "name" => posting[:title],
        "lever-uuid" => posting[:lever_uuid],
        "slug" => posting[:slug],
        "team" => team["name"],
        "team-reference" => team["_id"],
        "commitment" => posting[:commitment],
        "location" => posting[:location],
        "description-html" => posting[:description_html],
        "closing-html" => posting[:closing_html],
        "link" => posting[:apply_url],
      }}
    )

    {:ok, response} = HTTPoison.put(url, body, headers, [])
    IO.inspect(response)


    {:ok, results} = response.body() |> JSON.decode()

    results
  end

  def create_item (posting) do
    IO.puts("To be Created:")
    IO.inspect(posting[:lever_uuid])

    credentials = "f05f256dd66a6f010e3b025287dd9fe67fc8c6a7a9c30c37b39f5cb05c272ac7"
    headers = ["Authorization": "Bearer #{credentials}", "Content-Type": "application/json", "accept-version": "1.0.0"]
    url = @webflow_endpoint <> "collections/" <> @web_collection_id <> "/items"

    teams = retrieve_teams()
    team = Enum.find(teams["items"], fn (t) -> t["name"] == posting[:team] end)

    body = Poison.encode!(
      %{ "fields" => %{
        "_archived" => false,
        "_draft" => false,
        "name" => posting[:title],
        "lever-uuid" => posting[:lever_uuid],
        "slug" => posting[:slug],
        "team" => team["name"],
        "team-reference" => team["_id"],
        "commitment" => posting[:commitment],
        "location" => posting[:location],
        "description-html" => posting[:description_html],
        "closing-html" => posting[:closing_html],
        "link" => posting[:apply_url],
      }}
    )

    {:ok, response} = HTTPoison.post(url, body, headers, [])
    {:ok, results} = response.body() |> JSON.decode()

    results
  end

  defp process_posting(posting, existing_list) do
    cond do
      Enum.member?(existing_list, posting[:lever_uuid]) === true ->
        # Need to add webflow id
        update_item(posting)
      Enum.member?(existing_list, posting[:lever_uuid]) === false ->
        create_item(posting)
      true ->
        IO.puts("Don't know how to process item")
    end
  end

  def retrieve_teams() do
    credentials = "f05f256dd66a6f010e3b025287dd9fe67fc8c6a7a9c30c37b39f5cb05c272ac7"
    headers = ["Authorization": "Bearer #{credentials}", "Accept": "application/json", "accept-version": "1.0.0"]
    url = @webflow_endpoint <> "collections/" <> @team_collection_id <> "/items"

    {:ok, response} = HTTPoison.get(url,headers, [])
    {:ok, results} = response.body() |> JSON.decode()

    results
  end

  def retrieve_postings(source = "webflow") do
    credentials = "f05f256dd66a6f010e3b025287dd9fe67fc8c6a7a9c30c37b39f5cb05c272ac7"
    headers = ["Authorization": "Bearer #{credentials}", "Accept": "application/json", "accept-version": "1.0.0"]
    url = @webflow_endpoint <> "collections/" <> @web_collection_id <> "/items"

    {:ok, response} = HTTPoison.get(url,headers, [])
    {:ok, results} = response.body() |> JSON.decode()

    results
  end


  def retrieve_postings(source = "lever") do
    credentials = "xj/YG/+Fs11bzbBPP8Sw40TldaqhV7CB3h8Yecup6kKueSOf:" |> Base.encode64()
    headers = ["Authorization": "Basic #{credentials}", "Accept": "application/json"]
    url = @lever_endpoint <> "postings"

    {:ok, response} = HTTPoison.get(url,headers, [])
    {:ok, results} = response.body() |> JSON.decode()

    postings =
      results["data"]
      |> Enum.filter(fn (p) -> p["distributionChannels"] != nil end)
      |> Enum.filter(fn (p) -> Enum.member?(p["distributionChannels"], "public") end)
      |> Enum.map(&parse_posting/1)
  end

  defp parse_posting(posting) do
      # Parse this into the structure that we need to import into webflow
      item = %{
        lever_uuid: posting["id"],
        title: posting["text"],
        slug: Slug.slugify(posting["text"]),
        team: posting["categories"]["team"],
        commitment: posting["categories"]["commitment"],
        location: posting["categories"]["location"],
        description_html: generate_description(posting["content"]),
        closing_html: posting["content"]["closingHtml"],
        apply_url: posting["urls"]["apply"],
      }
  end

  defp generate_description(content) do
    description = content["descriptionHtml"]

    onboarding_lists = for list <- content["lists"] do
       "<p style='font-weight:bold'>" <> list["text"] <> "</p><ul>" <> list["content"] <> "</ul>"
    end

    Enum.join([description, onboarding_lists], " ")
  end
end
