int canvasW = 960;
int canvasH = 680;

ArrayList<ShapeType> shapeTypes = new ArrayList<ShapeType>();
ArrayList<PlacedShape> leftPan = new ArrayList<PlacedShape>();
ArrayList<PlacedBlock> rightPan = new ArrayList<PlacedBlock>();

boolean teacherMode = true;
int selectedShapeIndex = 0;

int[] blockWeights = {1, 2, 5};
int[] studentGuesses;
String guessFeedback = "";

PFont uiFont;

PlacedShape draggingShape = null;
PlacedBlock draggingBlock = null;
float dragOffsetX = 0;
float dragOffsetY = 0;

int activeShapeCount = 3;
int screenState = 0;

void setup() {
  size(canvasW, canvasH);
  uiFont = createFont("Arial", 16);
  textFont(uiFont);

  shapeTypes.add(new ShapeType("Circle", color(66, 135, 245)));
  shapeTypes.add(new ShapeType("Square", color(245, 166, 35)));
  shapeTypes.add(new ShapeType("Triangle", color(46, 204, 113)));

  syncStudentGuesses();
}

void draw() {
  background(250);
  if (screenState == 0) {
    drawTitleScreen();
  } else if (screenState == 1) {
    drawInstructionsScreen();
  } else {
    drawHeader();
    drawScale();
    drawTeacherPanel();
    drawStudentPanel();
    drawPanContents();
    drawStatus();
    drawDropHints();
  }
}

void drawHeader() {
  fill(30);
  textSize(20);
  text("Balance Lab", 20, 32);
  textSize(14);
  text(teacherMode ? "Teacher Mode (press S for student)" : "Student Mode (press T for teacher)", 20, 52);
  text("Goal: Balance the scale by matching the weight of the secret shapes on the left.", 20, 72);
}

void drawTitleScreen() {
  fill(30);
  textSize(32);
  text("Balance Lab", 40, 70);
  textSize(16);
  text("Teacher setup: set shape weights, choose how many shapes to use, then start the game.", 40, 100);

  float panelX = 40;
  float panelY = 140;
  float panelW = 420;
  float panelH = 360;
  fill(245);
  stroke(200);
  rect(panelX, panelY, panelW, panelH, 10);

  fill(30);
  textSize(18);
  text("Setup Shapes", panelX + 16, panelY + 30);
  textSize(13);
  text("Adjust hidden weights with +/- buttons.", panelX + 16, panelY + 52);

  float iconY = panelY + 90;
  for (int i = 0; i < shapeTypes.size(); i++) {
    ShapeType shape = shapeTypes.get(i);
    float rowY = iconY + i * 70;
    float iconX = panelX + 20;
    shape.drawIcon(iconX, rowY, 30);
    fill(30);
    textSize(13);
    text(shape.name, iconX + 50, rowY + 5);
    text("Weight: " + shape.weight, iconX + 50, rowY + 25);
    drawButton(iconX + 200, rowY - 12, 22, 20, "+");
    drawButton(iconX + 228, rowY - 12, 22, 20, "-");
  }

  float countY = panelY + panelH - 70;
  textSize(14);
  text("Shapes in play: " + activeShapeCount, panelX + 16, countY);
  drawButton(panelX + 200, countY - 16, 22, 20, "+");
  drawButton(panelX + 228, countY - 16, 22, 20, "-");

  float buttonY = panelY + panelH + 30;
  drawButton(panelX, buttonY, 140, 30, "Start Game");
  drawButton(panelX + 160, buttonY, 140, 30, "Instructions");
}

void drawInstructionsScreen() {
  fill(30);
  textSize(26);
  text("How to Play", 40, 60);
  textSize(14);
  text("Teacher: Use the setup screen to set each shape's hidden weight and choose how many shapes to use.", 40, 100);
  text("Start the game to let students work. Students drag shapes/blocks to balance the scale.", 40, 125);
  text("Students can click the guess +/- controls to enter how much each shape weighs.", 40, 150);
  text("Use 'Check Guesses' to see how many weights are correct.", 40, 175);
  text("Drag items off a pan to remove them.", 40, 200);
  drawButton(40, 240, 120, 30, "Back");
}

void drawScale() {
  float baseX = canvasW * 0.6;
  float baseY = canvasH * 0.55;
  float beamLength = 340;
  float leftWeight = totalLeftWeight();
  float rightWeight = totalRightWeight();
  float diff = rightWeight - leftWeight;
  float maxTilt = PI / 10.0;
  float angle = constrain(diff / 20.0, -1, 1) * maxTilt;

  stroke(60);
  strokeWeight(4);
  line(baseX, baseY + 120, baseX, baseY - 40);
  triangle(baseX - 35, baseY + 120, baseX + 35, baseY + 120, baseX, baseY + 70);

  pushMatrix();
  translate(baseX, baseY - 40);
  rotate(angle);
  line(-beamLength / 2, 0, beamLength / 2, 0);

  float panOffset = 120;
  drawPan(-beamLength / 2, panOffset);
  drawPan(beamLength / 2, panOffset);
  popMatrix();
}

void drawPan(float x, float y) {
  stroke(80);
  line(x, 0, x, y - 30);
  ellipse(x, y, 160, 26);
}

void drawTeacherPanel() {
  float panelX = 20;
  float panelY = 110;
  float panelW = 340;
  float panelH = 300;

  fill(245);
  stroke(200);
  rect(panelX, panelY, panelW, panelH, 8);
  fill(30);
  textSize(16);
  text("Teacher Tools", panelX + 12, panelY + 26);
  textSize(13);
  text("Click a shape to add it to the left pan.", panelX + 12, panelY + 48);
  text("Adjust weights with +/- buttons.", panelX + 12, panelY + 66);

  float iconY = panelY + 92;
  for (int i = 0; i < activeShapeCount; i++) {
    ShapeType shape = shapeTypes.get(i);
    float iconX = panelX + 20;
    float rowY = iconY + i * 70;
    shape.drawIcon(iconX, rowY, 30);

    fill(30);
    textSize(13);
    text(shape.name, iconX + 50, rowY + 5);

    String weightLabel = teacherMode ? "Weight: " + shape.weight : "Weight: ?";
    text(weightLabel, iconX + 50, rowY + 25);

    if (!teacherMode) {
      text("Guess: " + studentGuesses[i], iconX + 50, rowY + 45);
      drawButton(iconX + 200, rowY + 28, 22, 20, "+");
      drawButton(iconX + 228, rowY + 28, 22, 20, "-");
    }

    drawButton(iconX + 200, rowY - 12, 22, 20, "+");
    drawButton(iconX + 228, rowY - 12, 22, 20, "-");

    if (i == selectedShapeIndex) {
      noFill();
      stroke(120, 120, 200);
      strokeWeight(2);
      rect(panelX + 10, rowY - 32, panelW - 20, 56, 6);
    }
  }

  float clearY = panelY + panelH - 40;
  drawButton(panelX + 20, clearY, 90, 26, "Clear");
  drawButton(panelX + 120, clearY, 90, 26, "Undo L");
  drawButton(panelX + 220, clearY, 90, 26, "Undo R");
}

void drawStudentPanel() {
  float panelX = 20;
  float panelY = 430;
  float panelW = 340;
  float panelH = 220;

  fill(245);
  stroke(200);
  rect(panelX, panelY, panelW, panelH, 8);
  fill(30);
  textSize(16);
  text("Student Blocks", panelX + 12, panelY + 26);
  textSize(13);
  text("Drag blocks to the right pan or click to add.", panelX + 12, panelY + 48);

  float blockY = panelY + 80;
  for (int i = 0; i < blockWeights.length; i++) {
    float blockX = panelX + 20 + i * 100;
    drawWeightBlock(blockX, blockY, blockWeights[i]);
  }

  drawButton(panelX + 20, panelY + panelH - 40, 120, 26, "Clear Right");
  drawButton(panelX + 150, panelY + panelH - 40, 120, 26, "Check Guesses");
}

void drawWeightBlock(float x, float y, int weight) {
  fill(230, 230, 255);
  stroke(120);
  rect(x, y, 70, 50, 6);
  fill(40);
  textSize(18);
  text(weight + "", x + 26, y + 32);
}

void drawPanContents() {
  arrangeLeftPan();
  arrangeRightPan();

  for (PlacedShape shape : leftPan) {
    shape.draw();
  }

  for (PlacedBlock block : rightPan) {
    block.draw();
  }
}

void drawStatus() {
  float leftWeight = totalLeftWeight();
  float rightWeight = totalRightWeight();
  float statusX = canvasW * 0.43;
  float statusY = canvasH - 36;

  fill(30);
  textSize(14);
  String leftLabel = teacherMode ? "Left total: " + leftWeight : "Left total: ?";
  String rightLabel = "Right total: " + rightWeight;
  text(leftLabel, statusX, statusY);
  text(rightLabel, statusX + 150, statusY);

  if (abs(leftWeight - rightWeight) < 0.01) {
    fill(46, 204, 113);
    text("Balanced!", statusX + 330, statusY);
  } else {
    fill(231, 76, 60);
    text("Not balanced", statusX + 330, statusY);
  }

  if (!teacherMode && guessFeedback.length() > 0) {
    fill(30);
    text(guessFeedback, statusX, statusY + 20);
  }
}

void drawDropHints() {
  if (draggingShape != null || draggingBlock != null) {
    float leftCenterX = leftPanCenterX();
    float rightCenterX = rightPanCenterX();
    float panCenterY = panCenterY();

    noFill();
    stroke(180, 180, 220);
    strokeWeight(2);
    ellipse(leftCenterX, panCenterY, 180, 70);
    ellipse(rightCenterX, panCenterY, 180, 70);
  }
}

float totalLeftWeight() {
  float sum = 0;
  for (PlacedShape shape : leftPan) {
    sum += shape.shape.weight;
  }
  return sum;
}

float totalRightWeight() {
  float sum = 0;
  for (PlacedBlock block : rightPan) {
    sum += block.weight;
  }
  return sum;
}

void arrangeLeftPan() {
  float leftX = leftPanCenterX();
  float leftY = panCenterY();
  int index = 0;
  for (PlacedShape shape : leftPan) {
    if (shape == draggingShape) {
      continue;
    }
    float offsetX = leftX + (index % 4) * 34 - 50;
    float offsetY = leftY - (index / 4) * 34;
    shape.x = offsetX;
    shape.y = offsetY;
    index++;
  }
}

void arrangeRightPan() {
  float rightX = rightPanCenterX();
  float rightY = panCenterY();
  int index = 0;
  for (PlacedBlock block : rightPan) {
    if (block == draggingBlock) {
      continue;
    }
    float offsetX = rightX + (index % 4) * 34 - 50;
    float offsetY = rightY - (index / 4) * 34;
    block.x = offsetX;
    block.y = offsetY;
    index++;
  }
}

float leftPanCenterX() {
  return canvasW * 0.6 - 170;
}

float rightPanCenterX() {
  return canvasW * 0.6 + 170;
}

float panCenterY() {
  return canvasH * 0.55 + 80;
}

void drawButton(float x, float y, float w, float h, String label) {
  fill(235);
  stroke(160);
  rect(x, y, w, h, 4);
  fill(40);
  textSize(12);
  text(label, x + 6, y + h - 6);
}

void mousePressed() {
  if (screenState == 0) {
    handleTitleClicks();
    return;
  }
  if (screenState == 1) {
    handleInstructionClicks();
    return;
  }
  if (handleDragStart()) {
    return;
  }
  handleTeacherClicks();
  handleStudentClicks();
}

void mouseDragged() {
  if (draggingShape != null) {
    draggingShape.x = mouseX - dragOffsetX;
    draggingShape.y = mouseY - dragOffsetY;
  }
  if (draggingBlock != null) {
    draggingBlock.x = mouseX - dragOffsetX;
    draggingBlock.y = mouseY - dragOffsetY;
  }
}

void mouseReleased() {
  if (draggingShape != null) {
    if (!overLeftPanArea(mouseX, mouseY)) {
      leftPan.remove(draggingShape);
    }
    draggingShape = null;
  }
  if (draggingBlock != null) {
    if (!overRightPanArea(mouseX, mouseY)) {
      rightPan.remove(draggingBlock);
    }
    draggingBlock = null;
  }
}

boolean handleDragStart() {
  for (int i = leftPan.size() - 1; i >= 0; i--) {
    PlacedShape shape = leftPan.get(i);
    if (shape.hit(mouseX, mouseY)) {
      draggingShape = shape;
      dragOffsetX = mouseX - shape.x;
      dragOffsetY = mouseY - shape.y;
      return true;
    }
  }

  for (int i = rightPan.size() - 1; i >= 0; i--) {
    PlacedBlock block = rightPan.get(i);
    if (block.hit(mouseX, mouseY)) {
      draggingBlock = block;
      dragOffsetX = mouseX - block.x;
      dragOffsetY = mouseY - block.y;
      return true;
    }
  }

  if (!teacherMode) {
    float panelX = 20;
    float panelY = 430;
    float blockY = panelY + 80;
    for (int i = 0; i < blockWeights.length; i++) {
      float blockX = panelX + 20 + i * 100;
      if (hit(blockX, blockY, 70, 50)) {
        PlacedBlock newBlock = new PlacedBlock(blockWeights[i], mouseX, mouseY);
        rightPan.add(newBlock);
        draggingBlock = newBlock;
        dragOffsetX = 35;
        dragOffsetY = 25;
        return true;
      }
    }
  }

  return false;
}

void handleTitleClicks() {
  float panelX = 40;
  float panelY = 140;
  float iconY = panelY + 90;

  for (int i = 0; i < shapeTypes.size(); i++) {
    float rowY = iconY + i * 70;
    float iconX = panelX + 20;
    if (hit(iconX + 200, rowY - 12, 22, 20)) {
      shapeTypes.get(i).weight += 1;
      return;
    }
    if (hit(iconX + 228, rowY - 12, 22, 20)) {
      shapeTypes.get(i).weight = max(0, shapeTypes.get(i).weight - 1);
      return;
    }
  }

  float countY = panelY + 360 - 70;
  if (hit(panelX + 200, countY - 16, 22, 20)) {
    activeShapeCount = min(shapeTypes.size(), activeShapeCount + 1);
    syncStudentGuesses();
    return;
  }
  if (hit(panelX + 228, countY - 16, 22, 20)) {
    activeShapeCount = max(1, activeShapeCount - 1);
    syncStudentGuesses();
    return;
  }

  float buttonY = panelY + 360 + 30;
  if (hit(panelX, buttonY, 140, 30)) {
    startGame();
    return;
  }
  if (hit(panelX + 160, buttonY, 140, 30)) {
    screenState = 1;
  }
}

void handleInstructionClicks() {
  if (hit(40, 240, 120, 30)) {
    screenState = 0;
  }
}

void handleTeacherClicks() {
  float panelX = 20;
  float panelY = 110;
  float iconY = panelY + 92;

  for (int i = 0; i < activeShapeCount; i++) {
    float rowY = iconY + i * 70;
    float iconX = panelX + 20;

    if (hit(iconX - 16, rowY - 16, 32, 32)) {
      selectedShapeIndex = i;
      addShapeToLeft(shapeTypes.get(i));
      return;
    }

    if (hit(iconX + 200, rowY - 12, 22, 20)) {
      if (teacherMode) {
        shapeTypes.get(i).weight += 1;
      }
      return;
    }

    if (hit(iconX + 228, rowY - 12, 22, 20)) {
      if (teacherMode) {
        shapeTypes.get(i).weight = max(0, shapeTypes.get(i).weight - 1);
      }
      return;
    }

    if (!teacherMode) {
      if (hit(iconX + 200, rowY + 28, 22, 20)) {
        studentGuesses[i] += 1;
        return;
      }
      if (hit(iconX + 228, rowY + 28, 22, 20)) {
        studentGuesses[i] = max(0, studentGuesses[i] - 1);
        return;
      }
    }
  }

  float clearY = panelY + 300 - 40;
  if (hit(panelX + 20, clearY, 90, 26)) {
    leftPan.clear();
    rightPan.clear();
    guessFeedback = "";
    return;
  }
  if (hit(panelX + 120, clearY, 90, 26)) {
    if (leftPan.size() > 0) {
      leftPan.remove(leftPan.size() - 1);
    }
    return;
  }
  if (hit(panelX + 220, clearY, 90, 26)) {
    if (rightPan.size() > 0) {
      rightPan.remove(rightPan.size() - 1);
    }
  }
}

void handleStudentClicks() {
  float panelX = 20;
  float panelY = 430;
  float blockY = panelY + 80;

  for (int i = 0; i < blockWeights.length; i++) {
    float blockX = panelX + 20 + i * 100;
    if (hit(blockX, blockY, 70, 50)) {
      addBlockToRight(blockWeights[i]);
      return;
    }
  }

  if (hit(panelX + 20, panelY + 220 - 40, 120, 26)) {
    rightPan.clear();
    return;
  }

  if (hit(panelX + 150, panelY + 220 - 40, 120, 26)) {
    checkGuesses();
  }
}

void addShapeToLeft(ShapeType shapeType) {
  PlacedShape shape = new PlacedShape(shapeType, leftPanCenterX(), panCenterY());
  leftPan.add(shape);
}

void addBlockToRight(int weight) {
  PlacedBlock block = new PlacedBlock(weight, rightPanCenterX(), panCenterY());
  rightPan.add(block);
}

void checkGuesses() {
  int correct = 0;
  for (int i = 0; i < activeShapeCount; i++) {
    if (studentGuesses[i] == int(shapeTypes.get(i).weight)) {
      correct++;
    }
  }
  guessFeedback = "Guess check: " + correct + " / " + activeShapeCount + " correct.";
}

boolean overLeftPanArea(float x, float y) {
  float centerX = leftPanCenterX();
  float centerY = panCenterY();
  return x >= centerX - 90 && x <= centerX + 90 && y >= centerY - 50 && y <= centerY + 50;
}

boolean overRightPanArea(float x, float y) {
  float centerX = rightPanCenterX();
  float centerY = panCenterY();
  return x >= centerX - 90 && x <= centerX + 90 && y >= centerY - 50 && y <= centerY + 50;
}

boolean hit(float x, float y, float w, float h) {
  return mouseX >= x && mouseX <= x + w && mouseY >= y && mouseY <= y + h;
}

void keyPressed() {
  if (key == 't' || key == 'T') {
    teacherMode = true;
  }
  if (key == 's' || key == 'S') {
    teacherMode = false;
  }
}

void startGame() {
  leftPan.clear();
  rightPan.clear();
  guessFeedback = "";
  teacherMode = false;
  screenState = 2;
  syncStudentGuesses();
}

void syncStudentGuesses() {
  studentGuesses = new int[shapeTypes.size()];
  for (int i = 0; i < studentGuesses.length; i++) {
    studentGuesses[i] = 1;
  }
}

class ShapeType {
  String name;
  int shapeColor;
  float weight = 3;

  ShapeType(String name, int shapeColor) {
    this.name = name;
    this.shapeColor = shapeColor;
  }

  void drawIcon(float x, float y, float size) {
    fill(shapeColor);
    stroke(80);
    if (name.equals("Circle")) {
      ellipse(x, y, size, size);
    } else if (name.equals("Square")) {
      rectMode(CENTER);
      rect(x, y, size, size, 4);
      rectMode(CORNER);
    } else {
      triangle(x, y - size * 0.6, x - size * 0.5, y + size * 0.4, x + size * 0.5, y + size * 0.4);
    }
  }
}

class PlacedShape {
  ShapeType shape;
  float x;
  float y;

  PlacedShape(ShapeType shape, float x, float y) {
    this.shape = shape;
    this.x = x;
    this.y = y;
  }

  void draw() {
    shape.drawIcon(x, y, 24);
  }

  boolean hit(float mx, float my) {
    return dist(mx, my, x, y) <= 16;
  }
}

class PlacedBlock {
  int weight;
  float x;
  float y;

  PlacedBlock(int weight, float x, float y) {
    this.weight = weight;
    this.x = x;
    this.y = y;
  }

  void draw() {
    fill(230, 230, 255);
    stroke(120);
    rect(x - 14, y - 14, 28, 28, 5);
    fill(40);
    textSize(12);
    text(weight + "", x - 4, y + 4);
  }

  boolean hit(float mx, float my) {
    return mx >= x - 14 && mx <= x + 14 && my >= y - 14 && my <= y + 14;
  }
}
