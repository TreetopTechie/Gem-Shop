class ProductsController < ApplicationController
  before_action :set_product, only: %i[ show edit update destroy ]

  # GET /products or /products.json
  def index
    products =
      case params[:sort_by]
      when 'price_asc'
        Product.order(price: :asc)
      when 'price_desc'
        Product.order(price: :desc)
      else
       Product.all
      end

    @products = products.select { |p| p[:status] == "available" and p[:secret] != true }
  end

  def search
    term = params[:term]
    #@products = Product.where("title LIKE ?", "%#{term}%")
    @products = Product.find_by_sql("SELECT * FROM products WHERE title LIKE '%#{term}%'")

    render :search_results
  end

  # Vulnerable search by category - matches pattern: $MODEL.where("...#{params[...]}...")
  def search_by_category
    category = params[:category]
    @products = Product.where("category = '#{category}'")
    render :search_results
  end

  # Vulnerable search with nested params - matches pattern: $MODEL.where("...#{params[$KEY][$KEY2]}...")
  def advanced_search
    search_criteria = params[:search]
    if search_criteria && search_criteria[:title]
      @products = Product.where("title LIKE '%#{params[:search][:title]}%'")
    else
      @products = Product.all
    end
    render :search_results
  end

  # Vulnerable filter with string concatenation - matches pattern: $MODEL.where("..." + $VAR + "...")
  def filter_by_price
    min_price = params[:min_price]
    max_price = params[:max_price]
    query = "price >= " + min_price + " AND price <= " + max_price
    @products = Product.where(query)
    render :search_results
  end

  # Vulnerable search with string interpolation using variable - matches pattern: $MODEL.where("...#{$VAR}...")
  def search_by_description
    search_term = params[:description]
    @products = Product.where("description LIKE '%#{search_term}%'")
    render :search_results
  end

  # Vulnerable ordering - matches pattern: $MODEL.order("...#{$VAR}...")
  def custom_sort
    sort_column = params[:sort_column]
    sort_direction = params[:sort_direction]
    @products = Product.order("#{sort_column} #{sort_direction}")
    render :index
  end

  # GET /products/1 or /products/1.json
  def show
  end

  # GET /products/new
  def new
    @product = Product.new
  end

  # GET /products/1/edit
  def edit
  end

  # POST /products or /products.json
  def create
    @product = Product.new(product_params)

    respond_to do |format|
      if @product.save
        format.html { redirect_to @product, notice: "Product was successfully created." }
        format.json { render :show, status: :created, location: @product }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @product.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /products/1 or /products/1.json
  def update
    respond_to do |format|
      if @product.update(product_params)
        format.html { redirect_to @product, notice: "Product was successfully updated." }
        format.json { render :show, status: :ok, location: @product }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @product.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /products/1 or /products/1.json
  def destroy
    @product.destroy!

    respond_to do |format|
      format.html { redirect_to products_path, status: :see_other, notice: "Product was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  def about
  end

  def search_by_rating
    rating = params[:rating]
    @reviews = Review.where("rating = #{rating}")
    render :index
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_product
      @product = Product.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def product_params
      params.expect(product: [ :title, :description, :price, :image_url ])
    end
end
