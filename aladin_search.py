import requests
import pandas as pd
import sys
import time

TTB_KEY = "ttbrlaguswls5251446001"
BASE_URL = "http://www.aladin.co.kr/ttb/api/ItemSearch.aspx"
QUERY_TYPE = "Author"  # Author : 저자검색 / Publisher : 출판사검색
QUERY_TYPE_LABEL = {"Author": "저자명", "Publisher": "출판사명"}
MULTI_CATEGORY = True

COLUMNS = [
    "title", "link", "author", "pubDate", "description",
    "isbn", "isbn13", "itemId", "priceSales", "priceStandard",
    "mallType", "stockStatus", "mileage", "cover",
    "categoryId", "categoryName", "publisher", "salesPoint",
    "adult", "fixedPrice", "customerReviewRank",
    "seriesId", "seriesLink", "seriesName"
]


def fetch_page(query, category_id, start):
    """알라딘 API 한 페이지 조회"""
    params = {
        "ttbkey": TTB_KEY,
        "Query": query,
        "QueryType": QUERY_TYPE, 
        "MaxResults": 20,
        "Sort": "Title",  # Title : 제목정렬 / PublishTime : 출간일정렬
        "start": start,
        "SearchTarget": "Book",
        "CategoryId": category_id,
        "output": "js",
        "Version": "20131101",
    }
    resp = requests.get(BASE_URL, params=params)
    resp.raise_for_status()
    return resp.json()


def extract_item(item):
    """item에서 필요한 필드 추출 (seriesInfo 포함)"""
    series = item.get("seriesInfo", {})
    return {
        "title": item.get("title", ""),
        "link": item.get("link", ""),
        "author": item.get("author", ""),
        "pubDate": item.get("pubDate", ""),
        "description": item.get("description", ""),
        "isbn": item.get("isbn", ""),
        "isbn13": item.get("isbn13", ""),
        "itemId": item.get("itemId", ""),
        "priceSales": item.get("priceSales", ""),
        "priceStandard": item.get("priceStandard", ""),
        "mallType": item.get("mallType", ""),
        "stockStatus": item.get("stockStatus", ""),
        "mileage": item.get("mileage", ""),
        "cover": item.get("cover", ""),
        "categoryId": item.get("categoryId", ""),
        "categoryName": item.get("categoryName", ""),
        "publisher": item.get("publisher", ""),
        "salesPoint": item.get("salesPoint", ""),
        "adult": item.get("adult", ""),
        "fixedPrice": item.get("fixedPrice", ""),
        "customerReviewRank": item.get("customerReviewRank", ""),
        "seriesId": series.get("seriesId", ""),
        "seriesLink": series.get("seriesLink", ""),
        "seriesName": series.get("seriesName", ""),
    }


def search_all(query, category_id):
    """모든 페이지를 순회하며 전체 결과 수집"""
    first = fetch_page(query, category_id, start=1)
    total = first.get("totalResults", 0)
    print(f"총 검색 결과: {total}건")

    items = [extract_item(item) for item in first.get("item", [])]

    # 2페이지부터 끝까지
    page = 2
    while len(items) < total:
        time.sleep(0.3)  # API 부하 방지
        data = fetch_page(query, category_id, start=page)
        page_items = data.get("item", [])
        if not page_items:
            break
        items.extend(extract_item(item) for item in page_items)
        print(f"  {len(items)} / {total} 수집 완료")
        page += 1

    return items


def main():
    label = QUERY_TYPE_LABEL.get(QUERY_TYPE, QUERY_TYPE)
    query = input(f"{label} 입력: ").strip()

    if MULTI_CATEGORY:
        category_ids = []
        print("카테고리ID를 하나씩 입력하세요 (입력 완료 시 빈 값으로 Enter):")
        while True:
            cid = input("  카테고리ID: ").strip()
            if not cid:
                break
            category_ids.append(cid)
        if not category_ids:
            category_ids = ["0"]
    else:
        category_ids = [input("카테고리ID 입력 (없으면 Enter): ").strip() or "0"]

    all_items = []
    for category_id in category_ids:
        print(f"\n'{query}' (카테고리: {category_id}) 검색 중...")
        items = search_all(query, category_id)
        all_items.extend(items)

    if not all_items:
        print("검색 결과가 없습니다.")
        return

    df = pd.DataFrame(all_items, columns=COLUMNS)
    cat_label = "_".join(category_ids)
    filename = f"aladin_{query}_{cat_label}.xlsx"
    df.to_excel(filename, index=False, engine="openpyxl")
    print(f"\n완료! {len(all_items)}건 저장 → {filename}")


if __name__ == "__main__":
    main()
