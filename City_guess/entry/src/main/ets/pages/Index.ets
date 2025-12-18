import { City, allCityData } from '../CityData';

interface GuessRecord {
  cityName: string;
  direction: string;
  distance: number;
  id: number;
}

@Entry
@Component
struct CityGuessGame {
  // 游戏状态
  @State currentDifficulty: string = 'easy';
  @State target: City = {
    name: "北京",
    lat: 39.9042,
    lng: 116.4074,
    difficulty: 'easy'
  };
  @State inputText: string = "";
  @State tipText: string = "请先选择难度，然后开始猜测城市！";
  @State guessCount: number = 0;
  @State isGameOver: boolean = false;
  @State isClickLoading: boolean = false;
  @State guessRecords: GuessRecord[] = [];
  private recordIdCounter: number = 1;
  @State currentCities: City[] = [];
  private cityMap: Map<string, City> = new Map();

  // 刷新触发器
  @State refreshFlag: boolean = false;

  aboutToAppear(): void {
    console.log('应用启动，开始初始化');

    // 默认使用简单难度初始化
    this.updateCurrentCities('easy');
    this.target = this.getRandomCity();

    // 确保UI刷新
    this.forceRefresh();
  }

  // 强制刷新方法
  private forceRefresh(): void {
    this.refreshFlag = !this.refreshFlag;
  }

  // 更新当前可用的城市数据
  private updateCurrentCities(difficulty: string): void {
    if (difficulty === 'easy') {
      this.currentCities = allCityData.filter(city => city.difficulty === 'easy');
    } else if (difficulty === 'hard') {
      this.currentCities = allCityData.filter(city =>
      city.difficulty === 'easy' || city.difficulty === 'hard'
      );
    } else { // 'all' 地狱模式
      this.currentCities = allCityData;
    }

    // 重新构建城市映射
    this.cityMap.clear();
    this.currentCities.forEach(city => {
      this.cityMap.set(city.name, city);
    });

    console.log(`难度 ${difficulty}: ${this.currentCities.length} 个城市`);
  }

  // 获取随机城市
  private getRandomCity(): City {
    if (this.currentCities.length === 0) {
      return {
        name: "北京",
        lat: 39.9042,
        lng: 116.4074,
        difficulty: 'easy'
      };
    }
    const randomIndex = Math.floor(Math.random() * this.currentCities.length);
    return this.currentCities[randomIndex];
  }

  // 选择难度
  private selectDifficulty(difficulty: string): void {
    console.log('选择难度:', difficulty);
    this.currentDifficulty = difficulty;
    this.updateCurrentCities(difficulty);
    this.target = this.getRandomCity();
    this.tipText = `已切换到${difficulty === 'easy' ? '简单' : difficulty === 'hard' ? '困难' : '地狱'}模式，可以开始猜测了！`;
    this.resetGame();
    this.forceRefresh();
  }

  // 重置游戏
  private resetGame(): void {
    this.target = this.getRandomCity();
    this.inputText = "";
    this.guessCount = 0;
    this.isGameOver = false;
    this.isClickLoading = false;
    this.guessRecords = [];
    this.recordIdCounter = 1;
    this.forceRefresh();
  }

  // 快速计算距离
  private calculateDistanceFast(lat1: number, lng1: number, lat2: number, lng2: number): number {
    const R = 6371.0;
    const dLat = (lat2 - lat1) * Math.PI / 180;
    const dLng = (lng2 - lng1) * Math.PI / 180;

    const cosLat1 = Math.cos(lat1 * Math.PI / 180);
    const cosLat2 = Math.cos(lat2 * Math.PI / 180);

    const a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
      cosLat1 * cosLat2 *
      Math.sin(dLng / 2) * Math.sin(dLng / 2);

    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return Math.round(R * c * 10) / 10;
  }

  // 计算方位
  private calculateDirection(lat1: number, lng1: number, lat2: number, lng2: number): string {
    let dir = "";

    const latDiff = lat2 - lat1;
    const lngDiff = lng2 - lng1;

    if (Math.abs(latDiff) < 0.1 && Math.abs(lngDiff) < 0.1) {
      return "同一位置";
    }

    if (lngDiff > 0.5) dir += "东";
    else if (lngDiff < -0.5) dir += "西";

    if (latDiff > 0.5) dir += "北";
    else if (latDiff < -0.5) dir += "南";

    if (!dir) {
      dir = "附近";
    }

    return dir;
  }

  // 处理猜测逻辑
  private handleGuess(): void {
    if (this.isClickLoading) return;

    if (this.currentCities.length === 0) {
      this.tipText = "请先选择游戏难度！";
      this.forceRefresh();
      return;
    }

    const guessCity = this.inputText.trim();
    if (!guessCity) {
      this.tipText = "请输入城市名称！";
      this.forceRefresh();
      return;
    }

    this.isClickLoading = true;
    this.forceRefresh();

    try {
      const guess = this.cityMap.get(guessCity);
      if (!guess) {
        this.tipText = "城市不存在！请重新输入";
        this.isClickLoading = false;
        this.forceRefresh();
        return;
      }

      this.guessCount++;

      if (guess.name === this.target.name) {
        this.tipText = `恭喜猜对了！总共猜了${this.guessCount}次`;
        this.isGameOver = true;
        this.isClickLoading = false;
        this.forceRefresh();
        return;
      }

      const distance = this.calculateDistanceFast(
        guess.lat, guess.lng,
        this.target.lat, this.target.lng
      );

      const direction = this.calculateDirection(
        guess.lat, guess.lng,
        this.target.lat, this.target.lng
      );

      this.tipText = `目标城市在${direction}方向，距离${distance}公里`;

      const newRecord: GuessRecord = {
        cityName: guess.name,
        direction: direction,
        distance: distance,
        id: this.recordIdCounter++
      };

      this.guessRecords = [...this.guessRecords, newRecord];
      this.inputText = "";
      this.forceRefresh();

    } catch (error) {
      console.error("处理出错:", error);
      this.tipText = "处理出错，请重试";
      this.forceRefresh();
    } finally {
      this.isClickLoading = false;
      this.forceRefresh();
    }
  }

  build() {

    Column() {

      // 顶部标题区域
      Column() {
        Row() {


          Text('中国城市猜测')
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor('#333333')
            .margin({ left: 10 })
        }
        .justifyContent(FlexAlign.Center)
        .width('100%')


      }
      .margin({ top: 30 })

      // 难度选择区域
      Column({ space: 10 }) {
        Text('请选择游戏难度')
          .fontSize(18)
          .fontColor('#333333')
          .fontWeight(FontWeight.Medium)
          .margin({ bottom: 10 })

        Row({ space: 10 }) {
          Button('简单模式')
            .onClick(() => {
              console.log('简单模式按钮点击');
              this.selectDifficulty('easy');
            })
            .width('30%')
            .height(50)
            .backgroundColor(this.currentDifficulty === 'easy' ? '#4CAF50' : '#E0E0E0')
            .fontColor(this.currentDifficulty === 'easy' ? Color.White : '#666666')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .stateEffect(true)
            .borderRadius(8)

          Button('困难模式')
            .onClick(() => {
              console.log('困难模式按钮点击');
              this.selectDifficulty('hard');
            })
            .width('30%')
            .height(50)
            .backgroundColor(this.currentDifficulty === 'hard' ? '#FF9800' : '#E0E0E0')
            .fontColor(this.currentDifficulty === 'hard' ? Color.White : '#666666')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .stateEffect(true)
            .borderRadius(8)

          Button('地狱模式')
            .onClick(() => {
              console.log('地狱模式按钮点击');
              this.selectDifficulty('all');
            })
            .width('30%')
            .height(50)
            .backgroundColor(this.currentDifficulty === 'all' ? '#F44336' : '#E0E0E0')
            .fontColor(this.currentDifficulty === 'all' ? Color.White : '#666666')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .stateEffect(true)
            .borderRadius(8)
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)

        // 当前难度标签
        Row() {
          Text('当前难度：')
            .fontSize(14)
            .fontColor('#666666')
            .margin({ right: 8 })

          Text(
            this.currentDifficulty === 'easy' ? '简单' :
              this.currentDifficulty === 'hard' ? '困难' : '地狱'
          )
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor('#FFFFFF')
            .padding({ left: 12, right: 12, top: 6, bottom: 6 })
            .borderRadius(15)
            .backgroundColor(
              this.currentDifficulty === 'easy' ? '#4CAF50' :
                this.currentDifficulty === 'hard' ? '#FF9800' : '#F44336'
            )
        }
        .margin({ top: 15 })
      }
      .width('90%')
      .padding({ top: 20, bottom: 20, left: 20, right: 20 })
      .border({ width: 1, color: '#E0E0E0', radius: 12 })
      .backgroundColor('#FFFFFF')
      .margin({ top: 20 })

      // 游戏统计区域
      Column({ space: 8 }) {
        Text(`当前城市库：${this.currentCities.length}个城市`)
          .fontSize(14)
          .fontColor('#666666')

        Text(`猜测次数：${this.guessCount}`)
          .fontSize(16)
          .fontColor('#333333')
          .fontWeight(FontWeight.Medium)
      }
      .margin({ top: 20 })

      // 游戏提示
      Text(this.tipText)
        .fontSize(16)
        .margin({ top: 20, bottom: 20 })
        .fontColor(this.isGameOver ? '#4CAF50' : '#333333')
        .maxLines(2)
        .textAlign(TextAlign.Center)
        .width('90%')

      // 输入框
      if (!this.isGameOver) {
        TextInput({
          placeholder: '输入城市名称（例：北京市、杭州市）',
          text: this.inputText
        })
          .onChange((value: string) => {
            this.inputText = value;
          })
          .onSubmit(() => {
            this.handleGuess();
          })
          .width('80%')
          .margin({ top: 10, bottom: 10 })
          .enabled(!this.isClickLoading)
          .backgroundColor('#FFFFFF')
          .borderRadius(8)
          .padding(10)
      }

      // 按钮区域
      Row({ space: 15 }) {
        if (!this.isGameOver) {
          Button(this.isClickLoading ? '处理中...' : '提交猜测')
            .onClick(() => {
              this.handleGuess();
            })
            .width(120)
            .height(40)
            .enabled(!this.isClickLoading)
            .backgroundColor(this.isClickLoading ? '#CCCCCC' : '#2196F3')
            .fontColor('#FFFFFF')
            .fontSize(15)
            .stateEffect(true)
            .borderRadius(8)

          Button('重新开始')
            .onClick(() => {
              this.resetGame();
            })
            .width(120)
            .height(40)
            .backgroundColor('#757575')
            .fontColor('#FFFFFF')
            .fontSize(15)
            .stateEffect(true)
            .borderRadius(8)
        } else {
          Column({ space: 12 }) {
            Button('同难度再来一次')
              .onClick(() => {
                this.resetGame();
              })
              .width(200)
              .height(45)
              .backgroundColor(
                this.currentDifficulty === 'easy' ? '#4CAF50' :
                  this.currentDifficulty === 'hard' ? '#FF9800' : '#F44336'
              )
              .fontColor('#FFFFFF')
              .fontSize(16)
              .stateEffect(true)
              .borderRadius(10)

            Button('切换难度')
              .onClick(() => {
                this.resetGame();
                this.tipText = "请选择新的难度开始游戏";
                this.forceRefresh();
              })
              .width(200)
              .height(45)
              .backgroundColor('#666666')
              .fontColor('#FFFFFF')
              .fontSize(16)
              .stateEffect(true)
              .borderRadius(10)
          }
        }
      }
      .margin({ top: 10, bottom: 10 })

      // 猜测记录区域
      Column() {
        // 记录标题
        Row() {
          Text('你的猜测记录')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#333333')

          if (this.guessRecords.length > 0) {
            Text(`(${this.guessRecords.length}条)`)
              .fontSize(12)
              .fontColor('#999999')
              .margin({ left: 6 })
          }
        }
        .width('100%')
        .justifyContent(FlexAlign.Start)
        .margin({ bottom: 12 })

        // 记录列表区域
        Scroll() {
          Column({ space: 8 }) {
            if (this.guessRecords.length === 0) {
              Text('暂无猜测记录\n开始你的第一次猜测吧！')
                .fontSize(14)
                .fontColor('#999999')
                .textAlign(TextAlign.Center)
                .width('100%')
                .margin({ top: 50 })
            } else {
              ForEach(this.guessRecords, (item: GuessRecord, index: number) => {
                Column() {
                  Row() {
                    Text(`第${index + 1}次`)
                      .fontSize(12)
                      .fontColor('#666666')
                      .width('20%')

                    Text(`${item.cityName}`)
                      .fontSize(16)
                      .fontColor('#333333')
                      .fontWeight(FontWeight.Medium)
                      .width('35%')

                    Column({ space: 4 }) {
                      Text(`方位：${item.direction}`)
                        .fontSize(13)
                        .fontColor('#666666')
                      Text(`距离：${item.distance}公里`)
                        .fontSize(13)
                        .fontColor('#666666')
                    }
                    .width('45%')
                    .alignItems(HorizontalAlign.Start)
                  }
                  .width('100%')
                  .justifyContent(FlexAlign.SpaceBetween)
                }
                .width('100%')
                .padding({ top: 10, bottom: 30, left: 15, right: 15 })
                .border({ width: 1, color: '#E0E0E0', radius: 10 })
                .backgroundColor('#FFFFFF')
              }, (item: GuessRecord) => item.id.toString())
            }
          }
          .width('100%')
        }
        .width('100%')
        .height(250)
        .scrollBar(BarState.Auto)
      }
      .width('90%')
      .padding({ top: 15, bottom: 15, left: 20, right: 20 })
      .border({ width: 1, color: '#EEEEEE', radius: 12 })
      .backgroundColor('#F9F9F9')
      .margin({ top: 20, bottom: 30 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F0F9FF')
    .alignItems(HorizontalAlign.Center)
  }
}