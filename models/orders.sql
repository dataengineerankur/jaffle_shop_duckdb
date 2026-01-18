{% set payment_methods = ['credit_card', 'coupon', 'bank_transfer', 'gift_card'] %}

with orders as (

    select * from {{ ref('stg_orders') }}

),

payments as (

    select * from {{ ref('stg_payments') }}

),

order_payments as (

    select
        {% if var('scenario', 'default') == 'D2_type_change' -%}
        cast(order_id as varchar) as order_id,
        {% else -%}
        order_id,
        {% endif -%}

        {% for payment_method in payment_methods -%}
        sum(case when payment_method = '{{ payment_method }}' then amount else 0 end) as {{ payment_method }}_amount,
        {% endfor -%}

        sum(amount) as total_amount

    from payments

    group by 
        {% if var('scenario', 'default') == 'D2_type_change' -%}
        cast(order_id as varchar)
        {% else -%}
        order_id
        {% endif -%}

),

final as (

    select
        {% if var('scenario', 'default') == 'D2_type_change' -%}
        cast(orders.order_id as varchar) as order_id,
        {% else -%}
        orders.order_id,
        {% endif -%}
        orders.customer_id,
        orders.order_date,
        orders.status,

        {% for payment_method in payment_methods -%}

        order_payments.{{ payment_method }}_amount,

        {% endfor -%}

        order_payments.total_amount as amount

    from orders


    left join order_payments
        on orders.order_id = order_payments.order_id

)

select * from final
