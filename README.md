# s3

Main objective of this cookbook is to provide an interface for s3 through Chef.  The underlying implementation uses Boto3 and python in a wrapped script that is deployed on the server.
In order to achieve a level of isolation a virtualenv is created for s3 and it's dependencies installed.  This is of course idempotent and only happens if it needs to. this means that usage
of the s3 resource in anyway on a server with no supporting virtualenv will trigger the creation of an s3 virtualenv. Look inside libraries/s3.rb in order to see the defaults of it's location.
All possible variables have not been hardcoded in the resource but changing defaults may break the resource and thus should only be done if you are brave, wise, and have your cowboy hat on.

Currently, only upload and download are working. take a look at recipes/default.rb in order to find some examples.

TODO
====
1. Make :delete action work on the s3 resource. This requires refactoring to obtain a proper boto3 interface to do this.
2. Create a resource to create s3_buckets and in a way which subsequent s3 resource calls can depend on the creation and declaration of this bucket.
