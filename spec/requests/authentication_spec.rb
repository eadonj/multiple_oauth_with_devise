require 'spec_helper'

describe "authentication" do

  it "should work" do

    get "/users/auth/facebook"
    
    redirect_params = Rack::Utils.parse_query( URI(response.redirect_url).query )

    params = {
      # "origin" => "",
      "code"  => "AQD3wUAzRJdpuYUbpuQVJVchB836onpeW-EUYWFNXvvjHFKj0vbh4b44dWig-xlNrqMFxCFDxqiHU189HmeqtuRs3xbfd0iqMclj5If0wCojLQxCrM7d2NbmVjHpaNE5SoXhW2i2GyIGOyWUZMlHAvxwiYMGkQUMdhsqQcY5pGKt1Kv9W1PnvOAcGIdvvY29zMwBBXBPKJkzV1ZZi9dywPT0Xj9LORXKpgHnbP81XxFSo2myxo-00eCcPm1pwdkRTAMTsM8bTDExkUFr5CkVhMUEKcmfpjwgsRGKGlVTfj_ESuwY5sJCkhexWXu4VPbm7IdC9wtxOvQwxr8P7zT6XD-iN_mBeKf63wjWdzGbxw_bOg",
      "state" => redirect_params["state"],
    }

    binding.pry

    get "/users/auth/facebook/callback?#{params.to_param}"
    binding.pry

  end

end

