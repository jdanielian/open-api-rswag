# frozen_string_literal: true

require 'swagger_helper'

describe 'Blogs API', type: :request, swagger_doc: 'v1/swagger.json' do
  let(:api_key) { 'fake_key' }

  path '/blogs' do
    post 'Creates a blog' do
      tags 'Blogs'
      description 'Creates a new blog from provided data'
      operationId 'createBlog'
      consumes 'application/json'
      produces 'application/json'

      request_body_json schema: { '$ref' => '#/components/schemas/blog' },
                        examples: :blog

      request_body_text_plain
      request_body_xml schema: { '$ref' => '#/components/schemas/blog' }

      let(:blog) { { blog: { title: 'foo', content: 'bar' } } }

      response '201', 'blog created' do
        schema '$ref' => '#/components/schemas/blog'
        run_test!
      end

      response '422', 'invalid request' do
        schema '$ref' => '#/components/schemas/errors_object'
        let(:blog) { { blog: { title: 'foo' } } }

        run_test! do |response|
          expect(response.body).to include("can't be blank")
        end
      end
    end

    get 'Searches blogs' do
      tags 'Blogs'
      description 'Searches blogs by keywords'
      operationId 'searchBlogs'
      produces 'application/json'
      parameter name: :keywords, in: :query, type: 'string'

      let(:keywords) { 'foo bar' }

      response '200', 'success' do
        schema type: 'array', items: { '$ref' => '#/components/schemas/blog' }
        run_test!
      end

      response '406', 'unsupported accept header' do
        let(:Accept) { 'application/foo' }
        run_test!
      end
    end
  end

  path '/blogs/flexible' do
    post 'Creates a blog flexible body' do
      tags 'Blogs'
      description 'Creates a flexible blog from provided data'
      operationId 'createFlexibleBlog'
      consumes 'application/json'
      produces 'application/json'

      request_body_json schema: {
                                  :oneOf => [{'$ref' => '#/components/schemas/blog'},
                                             {'$ref' => '#/components/schemas/flexible_blog'}]
                                },
                        examples: :flexible_blog

      let(:flexible_blog) { { blog: { headline: 'my headline', text: 'my text' } } }

      response '201', 'flexible blog created' do
        schema :oneOf => [{'$ref' => '#/components/schemas/blog'},{'$ref' => '#/components/schemas/flexible_blog'}]
        run_test!
      end
    end
  end

  path '/blogs/alternate' do
    post 'Creates a blog - different :examples in requestBody' do
      tags 'Blogs'
      description 'Creates a new blog from provided data'
      operationId 'createAlternateBlog'
      consumes 'application/json'
      produces 'application/json'

      # NOTE: the externalValue: http://... is valid 3.0 spec, but swagger-UI does NOT support it yet
      # https://github.com/swagger-api/swagger-ui/issues/5433
      request_body_json schema: { '$ref' => '#/components/schemas/blog' },
                        examples: [:blog, {name: :external_blog,
                                           externalValue: 'http://api.sample.org/myjson_example'},
                                          {name: :another_example,
                                           '$ref' => '#/components/examples/flexible_blog_example'}]

      let(:blog) { { blog: { title: 'alt title', content: 'alt bar' } } }

      response '201', 'blog created' do
        schema '$ref' => '#/components/schemas/blog'
        run_test!
      end
    end
  end



  path '/blogs/{id}' do


    let(:id) { blog.id }
    let(:blog) { Blog.create(title: 'foo', content: 'bar', thumbnail: 'thumbnail.png') }

    get 'Retrieves a blog' do
      tags 'Blogs'
      description 'Retrieves a specific blog by id'
      operationId 'getBlog'
      produces 'application/json'

      parameter name: :id, in: :path, type: :string

      response '200', 'blog found' do
        header 'ETag', type: :string
        header 'Last-Modified', type: :string
        header 'Cache-Control', type: :string

        schema '$ref' => '#/components/schemas/blog'

        examples 'application/json' => {
          id: 1,
          title: 'Hello world!',
          content: 'Hello world and hello universe. Thank you all very much!!!',
          thumbnail: 'thumbnail.png'
        }

        let(:id) { blog.id }
        run_test!
      end

      response '404', 'blog not found' do
        let(:id) { 'invalid' }
        run_test!
      end
    end
  end


  path '/blogs/{id}/upload' do
    let(:id) { blog.id }
    let(:blog) { Blog.create(title: 'foo', content: 'bar') }

    put 'Uploads a blog thumbnail' do
      parameter name: :id, in: :path, type: :string

      tags 'Blogs'
      description 'Upload a thumbnail for specific blog by id'
      operationId 'uploadThumbnailBlog'
      consumes 'multipart/form-data'

      request_body_multipart schema: {properties: {:orderId => { type: :integer }, file: { type: :string, format: :binary }} }

      response '200', 'blog updated' do
        let(:file) { Rack::Test::UploadedFile.new(Rails.root.join('spec/fixtures/thumbnail.png')) }
        run_test!
      end
    end
  end
end

