import Foundation

enum BookCatalogData {
    static let all: [BookRecord] =
        worldLiterature + koreanLiterature + technical + nonfiction + edgeCases

    private static let worldLiterature: [BookRecord] = [
        .make("978893740001", "1984", author: "조지 오웰", publisher: "민음사", publishedAt: "20031120"),
        .make("978893740002", "데미안", author: "헤르만 헤세", publisher: "민음사", publishedAt: "20091215"),
        .make("978893740003", "위대한 개츠비", author: "F. 스콧 피츠제럴드", publisher: "민음사", publishedAt: "20100301"),
        .make("978893740004", "노인과 바다", author: "어니스트 헤밍웨이", publisher: "민음사", publishedAt: "20120110"),
        .make("978893740005", "이방인", author: "알베르 카뮈", publisher: "민음사", publishedAt: "20110328"),
        .make("978893740006", "변신", author: "프란츠 카프카", publisher: "민음사", publishedAt: "20110915"),
        .make("978893740007", "죄와 벌", author: "표도르 도스토예프스키", publisher: "민음사", publishedAt: "20120620"),
        .make("978893740008", "햄릿", author: "윌리엄 셰익스피어", publisher: "민음사", publishedAt: "20010405"),
        .make("978893740009", "앵무새 죽이기", author: "하퍼 리", publisher: "민음사", publishedAt: "20150701"),
        .make("978893740010", "오만과 편견", author: "제인 오스틴", publisher: "민음사", publishedAt: "20030910"),
        .make("978893740011", "젊은 베르테르의 슬픔", author: "요한 볼프강 폰 괴테", publisher: "민음사", publishedAt: "19991201"),
        .make("978893740012", "인간 실격", author: "다자이 오사무", publisher: "민음사", publishedAt: "20040805"),
        .make("978893740013", "수레바퀴 아래서", author: "헤르만 헤세", publisher: "민음사", publishedAt: "20130220"),
        .make("978893740014", "페스트", author: "알베르 카뮈", publisher: "민음사", publishedAt: "20110628"),
        .make("978893740015", "안나 카레니나", author: "레프 톨스토이", publisher: "민음사", publishedAt: "20120915"),
        .make("978893740016", "카라마조프가의 형제들", author: "표도르 도스토예프스키", publisher: "민음사", publishedAt: "20070730"),
        .make("978893740017", "파우스트", author: "요한 볼프강 폰 괴테", publisher: "민음사", publishedAt: "19991110"),
        .make("978893740018", "그리스인 조르바", author: "니코스 카잔차키스", publisher: "민음사", publishedAt: "20180412"),
        .make("978893740019", "폭풍의 언덕", author: "에밀리 브론테", publisher: "민음사", publishedAt: "20050825"),
        .make("978893740020", "백년의 고독", author: "가브리엘 가르시아 마르케스", publisher: "민음사", publishedAt: "20000615"),
        .make("978893740021", "롤리타", author: "블라디미르 나보코프", publisher: "민음사", publishedAt: "20130130"),
        .make("978893740023", "무기여 잘 있거라", author: "어니스트 헤밍웨이", publisher: "민음사", publishedAt: "20120820"),
    ]

    private static let koreanLiterature: [BookRecord] = [
        .make("978893740022", "82년생 김지영", author: "조남주", publisher: "민음사", publishedAt: "20161014"),
        .make("978895460001", "작별하지 않는다", author: "한강", publisher: "문학동네", publishedAt: "20210909"),
        .make("978895460002", "살인자의 기억법", author: "김영하", publisher: "문학동네", publishedAt: "20130725"),
        .make("978895460003", "검은 꽃", author: "김영하", publisher: "문학동네", publishedAt: "20030815"),
        .make("978895460004", "여행의 이유", author: "김영하", publisher: "문학동네", publishedAt: "20190417"),
        .make("978895460005", "하얼빈", author: "김훈", publisher: "문학동네", publishedAt: "20220801"),
        .make("978895460006", "칼의 노래", author: "김훈", publisher: "문학동네", publishedAt: "20010601"),
        .make("978893640001", "소년이 온다", author: "한강", publisher: "창비", publishedAt: "20140519"),
        .make("978893640002", "채식주의자", author: "한강", publisher: "창비", publishedAt: "20071030"),
        .make("978893640003", "엄마를 부탁해", author: "신경숙", publisher: "창비", publishedAt: "20081105"),
        .make("978893640004", "아몬드", author: "손원평", publisher: "창비", publishedAt: "20170331"),
    ]

    private static let technical: [BookRecord] = [
        .make("978896660001", "Clean Code", author: "로버트 C. 마틴", publisher: "인사이트", publishedAt: "20131224"),
        .make("978896660002", "이펙티브 자바", author: "조슈아 블로크", publisher: "인사이트", publishedAt: "20181101"),
        .make("978896660003", "함께 자라기", author: "김창준", publisher: "인사이트", publishedAt: "20181130"),
        .make("979115880001", "객체지향의 사실과 오해", author: "조영호", publisher: "위키북스", publishedAt: "20151117"),
        .make("979115880002", "오브젝트", author: "조영호", publisher: "위키북스", publishedAt: "20191216"),
        .make("979115880003", "도메인 주도 설계", author: "에릭 에반스", publisher: "위키북스", publishedAt: "20111128"),
        .make("979115680001", "Refactoring", author: "마틴 파울러", publisher: "한빛미디어", publishedAt: "20200401"),
        .make("979115680002", "스위프트 프로그래밍", author: "야곰", publisher: "한빛미디어", publishedAt: "20190701"),
        .make("979115680003", "모던 리액트 딥다이브", author: "김용찬", publisher: "한빛미디어", publishedAt: "20230601"),
    ]

    private static let nonfiction: [BookRecord] = [
        .make("978893490001", "사피엔스", author: "유발 하라리", publisher: "김영사", publishedAt: "20151120"),
        .make("978897000001", "총, 균, 쇠", author: "재레드 다이아몬드", publisher: "문학사상", publishedAt: "20051215"),
        .make("978898320001", "코스모스", author: "칼 세이건", publisher: "사이언스북스", publishedAt: "20061201"),
        .make("978893240001", "이기적 유전자", author: "리처드 도킨스", publisher: "을유문화사", publishedAt: "20181025"),
        .make("979118680001", "미움받을 용기", author: "기시미 이치로", publisher: "인플루엔셜", publishedAt: "20141117"),
        .make("979118680002", "파친코", author: "이민진", publisher: "인플루엔셜", publishedAt: "20180302"),
        .make("978895050001", "정의란 무엇인가", author: "마이클 샌델", publisher: "와이즈베리", publishedAt: "20140601"),
        .make("979118720001", "언어의 온도", author: "이기주", publisher: "말글터", publishedAt: "20160819"),
        .make("978899380001", "말의 품격", author: "이기주", publisher: "황소북스", publishedAt: "20170524"),
        .make("978897210001", "나미야 잡화점의 기적", author: "히가시노 게이고", publisher: "현대문학", publishedAt: "20121219"),
        .make("979119050001", "불편한 편의점", author: "김호연", publisher: "나무옆의자", publishedAt: "20210420"),
        .make("979119120001", "달러구트 꿈 백화점", author: "이미예", publisher: "팩토리나인", publishedAt: "20200708"),
        .make("979116500001", "세이노의 가르침", author: "세이노", publisher: "데이원", publishedAt: "20230302"),
    ]

    private static let edgeCases: [BookRecord] = [
        .make("978890110001", "그 많던 싱아는 누가 다 먹었을까", author: "박완서", publisher: "웅진지식하우스", publishedAt: "19921015"),
        .make("978893920001", "아주 오래된 농담", author: "박완서", publisher: "실천문학사", publishedAt: "20000920"),
        .make(
            "979119680001",
            "죽고 싶지만 떡볶이는 먹고 싶어: 우울증과 함께 살아가는 사람의 아주 사소하고 조금은 다행스러운 일상 기록",
            author: "백세희",
            publisher: "흔",
            publishedAt: "20180620"
        ),
        .make("978893290001", "숲", author: "조경란", publisher: "열린책들", publishedAt: "20050310", hasCover: false),
        .make("979112970001", "2024 수능 대비 문학 기출 총정리", publisher: "메가스터디북스", publishedAt: "20230612"),
        .make("979119990001", "퇴근길에 쓰는 문장들", author: "정한나", publishedAt: "20240418"),
        .make("978895570001", "절판된 프로그래밍 입문서", author: "이상민", publisher: "프리렉", publishedAt: "20081120", hasCover: false),
        .make("978899770001", "출간일 미정인 개발 에세이", author: "권용준", publisher: "로드북"),
        .make("979115680004", "스위프트 동시성 프로그래밍", author: "야곰", publisher: "한빛미디어", publishedAt: "20240801"),
    ]
}

extension BookRecord {
    fileprivate static func make(
        _ body: String,
        _ title: String,
        author: String? = nil,
        publisher: String? = nil,
        publishedAt: String? = nil,
        hasCover: Bool = true
    ) -> BookRecord {
        let isbn = body + Self.checkDigit(of: body)
        return BookRecord(
            isbn: isbn,
            title: title,
            author: author,
            publisher: publisher,
            publishedAt: publishedAt,
            coverImageURL: hasCover ? "https://picsum.photos/seed/\(isbn)/240/336" : nil
        )
    }

    private static func checkDigit(of body: String) -> String {
        let sum = body.compactMap(\.wholeNumberValue).enumerated().reduce(0) { total, pair in
            total + pair.element * (pair.offset.isMultiple(of: 2) ? 1 : 3)
        }
        return String((10 - sum % 10) % 10)
    }
}
