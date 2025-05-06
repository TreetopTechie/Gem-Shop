class OrdersController < ApplicationController

  def new
    # New order form, based on user's current cart
    cart = current_user.cart
    @cart_items = cart.cart_items.includes(:product)
    @cart_total = @cart_items.sum { |cart_item| cart_item.product.price }
    @order = Order.new
  end

  def check
    cart = current_user.cart
    @cart_items = cart.cart_items.includes(:product)
    @cart_total = @cart_items.sum { |cart_item| cart_item.product.price }
    # Page to confirm all the info is correct
    @order = current_user.orders.build(order_params)
    @order[:status] = "draft"
    @order.save
    session[:order_id] = @order.id
    render :check
  end

  def get_check
    cart = current_user.cart
    @cart_items = cart.cart_items.includes(:product)
    @cart_total = @cart_items.sum { |cart_item| cart_item.product.price }
    @order = current_user.orders.find(session[:order_id])
    render :check
  end

  def create
    # Create the order
    @order = current_user.orders.find(session[:order_id])
    cart = current_user.cart
    cart_items = cart.cart_items.includes(:product)

    # Create the order.order_products from the cart_items
    cart_items.each do |cart_item|
      @order.order_products.create(
        title: cart_item.product.title,
        description: cart_item.product.description,
        price: cart_item.product.price,
        image_url: cart_item.product.image_url,
        carat: cart_item.product.carat,
        secret: cart_item.product.secret,
        status: "in_order"
      )
    end

    # Set the status of all products in the user's cart to "in_order"
    # Delete all cart_items
    cart_items.each do |cart_item|
      cart_item.product.status = "in_order"
      cart_item.destroy()
    end

    # For the new order, sum all order_products
    #@order_total = @order.order_products.sum { |order_product| order_product.product.price }

    # Change order.status = "submitted"
    @order.status = "submitted"
    @order.save

    # Render order
    redirect_to order_path(@order.id), notice: 'Order was successfully created.'
  end

  def view
    @order = Order.includes(:order_products, :user)
                 .where(id: params[:id])
                 .or(Order.includes(:order_products, :user).where(user: current_user))
                 .first
    @order_products = @order.order_products
    @order_total = @order_products.sum { |op| op.price }
  end

  private

  def order_params
    params.require(:order).permit(:first_name, :last_name, :bank_account_number, :routing_number,
      :address_street, :address_second_line, :address_city, :address_state, :address_zip)
  end
end
