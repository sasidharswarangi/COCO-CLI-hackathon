import streamlit as st
from snowflake.snowpark.context import get_active_session

st.set_page_config(page_title="Supply Chain Analytics", page_icon="📦", layout="wide")

session = get_active_session()

def run_query(sql):
    return session.sql(sql).to_pandas()

# --- Sidebar ---
st.sidebar.title("Supply Chain Ontology")
page = st.sidebar.radio("Navigate", ["Dashboard", "Data Explorer", "Ask a Question"])

# --- Dashboard ---
if page == "Dashboard":
    st.title("Supply Chain Dashboard")
    st.markdown("Canonical metrics from `SUPPLY_CHAIN_ONTOLOGY.CORE`")

    # KPI Row
    col1, col2, col3, col4 = st.columns(4)

    # On-Time Delivery Rate
    otd = run_query("""
        WITH line_delivery AS (
            SELECT ol.ORDER_LINE_ID,
                   CASE WHEN MAX(sh.ACTUAL_DELIVERY_DATE) <= o.REQUESTED_DELIVERY_DATE THEN 1 ELSE 0 END AS is_on_time
            FROM SUPPLY_CHAIN_ONTOLOGY.CORE.ORDER_LINE ol
            JOIN SUPPLY_CHAIN_ONTOLOGY.CORE."ORDER" o ON ol.ORDER_ID = o.ORDER_ID
            JOIN SUPPLY_CHAIN_ONTOLOGY.CORE.SHIPMENT sh ON ol.ORDER_LINE_ID = sh.ORDER_LINE_ID
            WHERE ol.LINE_STATUS != 'CANCELLED' AND sh.ACTUAL_DELIVERY_DATE IS NOT NULL
            GROUP BY ol.ORDER_LINE_ID, o.REQUESTED_DELIVERY_DATE
        )
        SELECT ROUND(SUM(is_on_time)/COUNT(*)*100, 1) AS otd_rate, COUNT(*) AS total_lines, SUM(is_on_time) AS on_time
        FROM line_delivery
    """)
    col1.metric("On-Time Delivery", f"{otd['OTD_RATE'].iloc[0]}%", f"{int(otd['ON_TIME'].iloc[0])}/{int(otd['TOTAL_LINES'].iloc[0])} lines")

    # Fill Rate
    fr = run_query("""
        SELECT ROUND(SUM(QUANTITY_FULFILLED)/SUM(QUANTITY_ORDERED)*100, 1) AS fill_rate,
               SUM(QUANTITY_FULFILLED) AS fulfilled, SUM(QUANTITY_ORDERED) AS ordered
        FROM SUPPLY_CHAIN_ONTOLOGY.CORE.ORDER_LINE WHERE LINE_STATUS != 'CANCELLED'
    """)
    col2.metric("Fill Rate", f"{fr['FILL_RATE'].iloc[0]}%", f"{int(fr['FULFILLED'].iloc[0])}/{int(fr['ORDERED'].iloc[0])} units")

    # Avg Days of Inventory
    doi = run_query("""
        SELECT ROUND(SUM(QUANTITY_ON_HAND)/SUM(DAILY_USAGE_RATE), 1) AS avg_doi
        FROM SUPPLY_CHAIN_ONTOLOGY.CORE.PLANT_INVENTORY
        WHERE DAILY_USAGE_RATE > 0
    """)
    col3.metric("Avg Days of Inventory", f"{doi['AVG_DOI'].iloc[0]} days")

    # Total Orders
    orders = run_query("SELECT COUNT(*) AS cnt FROM SUPPLY_CHAIN_ONTOLOGY.CORE.\"ORDER\"")
    col4.metric("Total Orders", int(orders['CNT'].iloc[0]))

    st.divider()

    # Charts Row
    chart_col1, chart_col2 = st.columns(2)

    with chart_col1:
        st.subheader("Orders by Status")
        order_status = run_query("""
            SELECT ORDER_STATUS, COUNT(*) AS ORDER_COUNT
            FROM SUPPLY_CHAIN_ONTOLOGY.CORE."ORDER"
            GROUP BY ORDER_STATUS ORDER BY ORDER_COUNT DESC
        """)
        st.bar_chart(order_status.set_index("ORDER_STATUS"))

    with chart_col2:
        st.subheader("Days of Inventory by Plant")
        doi_plant = run_query("""
            SELECT pl.PLANT_NAME,
                   ROUND(SUM(pi.QUANTITY_ON_HAND)/SUM(pi.DAILY_USAGE_RATE), 1) AS DOI
            FROM SUPPLY_CHAIN_ONTOLOGY.CORE.PLANT_INVENTORY pi
            JOIN SUPPLY_CHAIN_ONTOLOGY.CORE.PLANT pl ON pi.PLANT_ID = pl.PLANT_ID
            WHERE pi.DAILY_USAGE_RATE > 0
            GROUP BY pl.PLANT_NAME ORDER BY DOI DESC
        """)
        st.bar_chart(doi_plant.set_index("PLANT_NAME"))

    st.divider()

    chart_col3, chart_col4 = st.columns(2)

    with chart_col3:
        st.subheader("Fill Rate by Part Category")
        fr_cat = run_query("""
            SELECT p.CATEGORY,
                   ROUND(SUM(ol.QUANTITY_FULFILLED)/NULLIF(SUM(ol.QUANTITY_ORDERED),0)*100, 1) AS FILL_RATE
            FROM SUPPLY_CHAIN_ONTOLOGY.CORE.ORDER_LINE ol
            JOIN SUPPLY_CHAIN_ONTOLOGY.CORE.PART p ON ol.PART_ID = p.PART_ID
            WHERE ol.LINE_STATUS != 'CANCELLED'
            GROUP BY p.CATEGORY ORDER BY FILL_RATE
        """)
        st.bar_chart(fr_cat.set_index("CATEGORY"))

    with chart_col4:
        st.subheader("Shipments by Carrier")
        carriers = run_query("""
            SELECT CARRIER, COUNT(*) AS SHIPMENT_COUNT
            FROM SUPPLY_CHAIN_ONTOLOGY.CORE.SHIPMENT
            GROUP BY CARRIER ORDER BY SHIPMENT_COUNT DESC
        """)
        st.bar_chart(carriers.set_index("CARRIER"))

    # Rejected Records
    st.divider()
    st.subheader("Rejected Records (from Ontology Mapper)")
    rejected = run_query("""
        SELECT SOURCE_TABLE, TARGET_TABLE, REJECTION_REASON, REJECTED_AT
        FROM SUPPLY_CHAIN_ONTOLOGY.CORE.REJECTED_RECORDS
        ORDER BY REJECTED_AT DESC
    """)
    if len(rejected) > 0:
        st.dataframe(rejected, use_container_width=True)
    else:
        st.info("No rejected records.")

# --- Data Explorer ---
elif page == "Data Explorer":
    st.title("Data Explorer")

    table = st.selectbox("Select Table", [
        "SUPPLIER", "PART", "PLANT", "CUSTOMER",
        "ORDER", "ORDER_LINE", "PLANT_INVENTORY", "SHIPMENT", "REJECTED_RECORDS"
    ])

    tbl_name = f'"ORDER"' if table == "ORDER" else table
    df = run_query(f"SELECT * FROM SUPPLY_CHAIN_ONTOLOGY.CORE.{tbl_name} LIMIT 500")
    st.write(f"**{len(df)} rows**")
    st.dataframe(df, use_container_width=True)

# --- Ask a Question ---
elif page == "Ask a Question":
    st.title("Ask a Question")
    st.markdown("Ask natural language questions about your supply chain data.")

    question = st.text_input("Your question:", placeholder="e.g. What is the fill rate for Electronics parts?")

    if question:
        st.markdown("---")

        q_lower = question.lower()

        if "fill rate" in q_lower:
            if any(w in q_lower for w in ["category", "electronics", "mechanical", "raw material", "fastener"]):
                result = run_query("""
                    SELECT p.CATEGORY,
                           ROUND(SUM(ol.QUANTITY_FULFILLED)/NULLIF(SUM(ol.QUANTITY_ORDERED),0)*100, 1) AS FILL_RATE_PCT,
                           SUM(ol.QUANTITY_FULFILLED) AS FULFILLED, SUM(ol.QUANTITY_ORDERED) AS ORDERED
                    FROM SUPPLY_CHAIN_ONTOLOGY.CORE.ORDER_LINE ol
                    JOIN SUPPLY_CHAIN_ONTOLOGY.CORE.PART p ON ol.PART_ID = p.PART_ID
                    WHERE ol.LINE_STATUS != 'CANCELLED'
                    GROUP BY p.CATEGORY ORDER BY FILL_RATE_PCT
                """)
            elif any(w in q_lower for w in ["supplier", "vendor"]):
                result = run_query("""
                    SELECT s.SUPPLIER_NAME,
                           ROUND(SUM(ol.QUANTITY_FULFILLED)/NULLIF(SUM(ol.QUANTITY_ORDERED),0)*100, 1) AS FILL_RATE_PCT
                    FROM SUPPLY_CHAIN_ONTOLOGY.CORE.ORDER_LINE ol
                    JOIN SUPPLY_CHAIN_ONTOLOGY.CORE.PART p ON ol.PART_ID = p.PART_ID
                    JOIN SUPPLY_CHAIN_ONTOLOGY.CORE.SUPPLIER s ON p.SUPPLIER_ID = s.SUPPLIER_ID
                    WHERE ol.LINE_STATUS != 'CANCELLED'
                    GROUP BY s.SUPPLIER_NAME ORDER BY FILL_RATE_PCT
                """)
            else:
                result = run_query("""
                    SELECT ROUND(SUM(QUANTITY_FULFILLED)/SUM(QUANTITY_ORDERED)*100, 1) AS FILL_RATE_PCT,
                           SUM(QUANTITY_FULFILLED) AS FULFILLED, SUM(QUANTITY_ORDERED) AS ORDERED
                    FROM SUPPLY_CHAIN_ONTOLOGY.CORE.ORDER_LINE WHERE LINE_STATUS != 'CANCELLED'
                """)
            st.dataframe(result, use_container_width=True)

        elif "on-time" in q_lower or "on time" in q_lower or "delivery rate" in q_lower:
            if any(w in q_lower for w in ["customer", "account"]):
                result = run_query("""
                    WITH ld AS (
                        SELECT ol.ORDER_LINE_ID, o.CUSTOMER_ID,
                               CASE WHEN MAX(sh.ACTUAL_DELIVERY_DATE) <= o.REQUESTED_DELIVERY_DATE THEN 1 ELSE 0 END AS is_on_time
                        FROM SUPPLY_CHAIN_ONTOLOGY.CORE.ORDER_LINE ol
                        JOIN SUPPLY_CHAIN_ONTOLOGY.CORE."ORDER" o ON ol.ORDER_ID = o.ORDER_ID
                        JOIN SUPPLY_CHAIN_ONTOLOGY.CORE.SHIPMENT sh ON ol.ORDER_LINE_ID = sh.ORDER_LINE_ID
                        WHERE ol.LINE_STATUS != 'CANCELLED' AND sh.ACTUAL_DELIVERY_DATE IS NOT NULL
                        GROUP BY ol.ORDER_LINE_ID, o.CUSTOMER_ID, o.REQUESTED_DELIVERY_DATE
                    )
                    SELECT c.CUSTOMER_NAME, ROUND(SUM(is_on_time)/COUNT(*)*100,1) AS OTD_RATE_PCT, COUNT(*) AS LINES
                    FROM ld JOIN SUPPLY_CHAIN_ONTOLOGY.CORE.CUSTOMER c ON ld.CUSTOMER_ID = c.CUSTOMER_ID
                    GROUP BY c.CUSTOMER_NAME ORDER BY OTD_RATE_PCT
                """)
            else:
                result = run_query("""
                    WITH ld AS (
                        SELECT ol.ORDER_LINE_ID,
                               CASE WHEN MAX(sh.ACTUAL_DELIVERY_DATE) <= o.REQUESTED_DELIVERY_DATE THEN 1 ELSE 0 END AS is_on_time
                        FROM SUPPLY_CHAIN_ONTOLOGY.CORE.ORDER_LINE ol
                        JOIN SUPPLY_CHAIN_ONTOLOGY.CORE."ORDER" o ON ol.ORDER_ID = o.ORDER_ID
                        JOIN SUPPLY_CHAIN_ONTOLOGY.CORE.SHIPMENT sh ON ol.ORDER_LINE_ID = sh.ORDER_LINE_ID
                        WHERE ol.LINE_STATUS != 'CANCELLED' AND sh.ACTUAL_DELIVERY_DATE IS NOT NULL
                        GROUP BY ol.ORDER_LINE_ID, o.REQUESTED_DELIVERY_DATE
                    )
                    SELECT ROUND(SUM(is_on_time)/COUNT(*)*100,1) AS OTD_RATE_PCT, SUM(is_on_time) AS ON_TIME, COUNT(*) AS TOTAL
                    FROM ld
                """)
            st.dataframe(result, use_container_width=True)

        elif "inventory" in q_lower or "days of" in q_lower or "doi" in q_lower or "stock" in q_lower:
            result = run_query("""
                SELECT pl.PLANT_NAME, p.PART_NAME, pi.QUANTITY_ON_HAND, pi.DAILY_USAGE_RATE,
                       ROUND(pi.QUANTITY_ON_HAND / NULLIF(pi.DAILY_USAGE_RATE, 0), 1) AS DAYS_OF_INVENTORY
                FROM SUPPLY_CHAIN_ONTOLOGY.CORE.PLANT_INVENTORY pi
                JOIN SUPPLY_CHAIN_ONTOLOGY.CORE.PLANT pl ON pi.PLANT_ID = pl.PLANT_ID
                JOIN SUPPLY_CHAIN_ONTOLOGY.CORE.PART p ON pi.PART_ID = p.PART_ID
                ORDER BY DAYS_OF_INVENTORY
            """)
            st.dataframe(result, use_container_width=True)

        elif "supplier" in q_lower or "vendor" in q_lower:
            result = run_query("SELECT * FROM SUPPLY_CHAIN_ONTOLOGY.CORE.SUPPLIER ORDER BY SUPPLIER_ID")
            st.dataframe(result, use_container_width=True)

        elif "order" in q_lower:
            result = run_query("""
                SELECT o.ORDER_ID, c.CUSTOMER_NAME, o.ORDER_DATE, o.REQUESTED_DELIVERY_DATE, o.ORDER_STATUS
                FROM SUPPLY_CHAIN_ONTOLOGY.CORE."ORDER" o
                JOIN SUPPLY_CHAIN_ONTOLOGY.CORE.CUSTOMER c ON o.CUSTOMER_ID = c.CUSTOMER_ID
                ORDER BY o.ORDER_DATE DESC
            """)
            st.dataframe(result, use_container_width=True)

        elif "reject" in q_lower or "bad" in q_lower or "failed" in q_lower:
            result = run_query("SELECT * FROM SUPPLY_CHAIN_ONTOLOGY.CORE.REJECTED_RECORDS ORDER BY REJECTED_AT DESC")
            st.dataframe(result, use_container_width=True)

        elif "plant" in q_lower or "warehouse" in q_lower or "facility" in q_lower:
            result = run_query("SELECT * FROM SUPPLY_CHAIN_ONTOLOGY.CORE.PLANT ORDER BY PLANT_ID")
            st.dataframe(result, use_container_width=True)

        elif "customer" in q_lower or "client" in q_lower:
            result = run_query("SELECT * FROM SUPPLY_CHAIN_ONTOLOGY.CORE.CUSTOMER ORDER BY CUSTOMER_ID")
            st.dataframe(result, use_container_width=True)

        elif "part" in q_lower or "product" in q_lower or "sku" in q_lower:
            result = run_query("SELECT * FROM SUPPLY_CHAIN_ONTOLOGY.CORE.PART ORDER BY PART_ID")
            st.dataframe(result, use_container_width=True)

        elif "shipment" in q_lower or "shipping" in q_lower or "carrier" in q_lower:
            result = run_query("""
                SELECT sh.SHIPMENT_ID, sh.SHIP_DATE, sh.ACTUAL_DELIVERY_DATE, sh.QUANTITY_SHIPPED, sh.CARRIER,
                       pl.PLANT_NAME
                FROM SUPPLY_CHAIN_ONTOLOGY.CORE.SHIPMENT sh
                JOIN SUPPLY_CHAIN_ONTOLOGY.CORE.PLANT pl ON sh.PLANT_ID = pl.PLANT_ID
                ORDER BY sh.SHIP_DATE DESC
            """)
            st.dataframe(result, use_container_width=True)

        else:
            st.warning("I can answer questions about: fill rate, on-time delivery, days of inventory, suppliers, parts, plants, customers, orders, shipments, and rejected records. Try rephrasing your question.")
