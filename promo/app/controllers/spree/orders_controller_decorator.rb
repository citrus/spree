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
    end
  end

  def apply_coupon_code
    return if @order.coupon_code.blank?
    if Spree::Promotion.exists?(:code => @order.coupon_code)
      fire_event('spree.checkout.coupon_code_added', :coupon_code => @order.coupon_code)
      true
    end
  end

end
