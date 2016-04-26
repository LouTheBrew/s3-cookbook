# s3

Main objective of this cookbook is to provide an interface for s3 through Chef.

Currently, only upload and download are working. take a look at recipes/default.rb in order to find some examples.

TODO
====
1. Make :delete action work on the s3 resource. This requires refactoring to obtain a proper boto3 interface to do this.
2. Create a resource to create s3_buckets and in a way which subsequent s3 resource calls can depend on the creation and declaration of this bucket.
