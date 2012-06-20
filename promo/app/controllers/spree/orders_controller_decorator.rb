Spree::OrdersController.class_eval do

  def update
    @order = current_order
    if @order.update_attributes(params[:order])
      # TODO refactor into protected method for use in the checkout controler
      if @order.coupon_code.present?

        if @order.adjustments.promotion.eligible.detect { |p| p.originator.promotion.code == @order.coupon_code }.present?
          flash[:notice] = t(:coupon_code_already_applied)
        else
          promotion = Spree::Promotion.find_by_code(@order.coupon_code)

          if promotion.present?
            if promotion.expired?
              flash[:error] = t(:coupon_code_expired)
              render :edit and return
            end

            if promotion.usage_limit_exceeded?
              flash[:error] = t(:coupon_code_max_usage)
              render :edit and return
            end

            fire_event('spree.checkout.coupon_code_added', :coupon_code => @order.coupon_code)
            promo = @order.adjustments.promotion.detect { |p| p.originator.promotion.code == @order.coupon_code }

            if promo.present? and promo.eligible
              fire_event('spree.checkout.coupon_code_added', :coupon_code => @order.coupon_code)
            elsif promo.present?
              flash[:error] = t(:coupon_code_not_eligible)
              render :edit and return
            else
              flash[:error] = t(:coupon_code_better_exists)
              render :edit and return
            end
          else
            flash[:error] = t(:coupon_code_not_found)
            render :edit and return
          end
        end
      end

      @order.line_items = @order.line_items.select {|li| li.quantity > 0 }
      fire_event('spree.order.contents_changed')
      respond_with(@order) { |format| format.html { redirect_to cart_path } }
    else
      respond_with(@order)
    end
  end

end
