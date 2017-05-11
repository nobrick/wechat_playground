# WechatPlayground

## Installation for development

Install dependencies:
- ImageMagick
- libjpeg

Install and start the following services:
- Redis
- Elasticsearch
- Sidekiq

Then run the following commands in the project's directory:

```
bundle install
rake db:elastic:create_index
rails server
```
