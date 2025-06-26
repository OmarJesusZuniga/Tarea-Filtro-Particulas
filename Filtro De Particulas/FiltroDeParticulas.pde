int size = 500;

class Ambiente {
  PVector position;
  PVector direction;
  float   angle;
  float   r;
  float   movimiento;
  float   errorMove;
  float   errorAngle;
  float   step;
  float   rotation;

  Ambiente(float x, float y, float angulo, float paso, float rotacion, float errMove, float errAng) {
    angle = angulo;
    direction = new PVector(cos(angle), sin(angle));
    position = new PVector(x, y);
    r = 5.0;
    movimiento = 0;
    errorMove = errMove;
    errorAngle = errAng;
    step = paso;
    rotation = rotacion;
  }

  void borders() {
    if (position.x < -r) position.x = size+r;
    if (position.y < -r) position.y = size+r;
    if (position.x > size+r) position.x = -r;
    if (position.y > size+r) position.y = -r;
  }

  void drawAgente() {
    float theta = direction.heading() + radians(90);
    pushMatrix();
    translate(position.x, position.y);
    rotate(theta);
    beginShape(TRIANGLES);
    vertex(0, -r*2);
    vertex(-r, r*2);
    vertex(r, r*2);
    endShape();
    popMatrix();
    position.x += direction.x*movimiento;
    position.y += direction.y*movimiento;
    borders();
    movimiento *= 0.95;
  }

  void right() {
    float angulo = rotation + randomGaussian()*errorAngle;
    angle += radians(angulo);
    direction = new PVector(cos(angle), sin(angle));
  }

  void left() {
    float angulo = rotation + randomGaussian()*errorAngle;
    angle -= radians(angulo);
    direction = new PVector(cos(angle), sin(angle));
  }

  void forward() {
    float amount = step+randomGaussian()*errorMove;
    movimiento += amount;
  }

  void backward() {
    float amount = step+randomGaussian()*errorMove;
    movimiento -= amount;
  }


  void draw() {
    fill(255, 255, 255);
    square(0, 0, size);
    drawAgente();
  }

  float senseX() {
    return position.x + randomGaussian() + errorMove;
  }

  float senseY() {
    return position.y + randomGaussian() * errorMove;
  }

  PVector senseDir() {
    float angulo = angle + randomGaussian()*errorAngle;
    PVector dir = new PVector(cos(angulo), sin(angulo));

    return dir;
  }

  float senseMove() {
    return movimiento+randomGaussian()*errorMove;
  }
};

class Agente {
  Ambiente hab;
  int numParticulas;
  ArrayList<particle> candidatos;

  class particle {
    PVector position;
    PVector direction;
    float angle;
    float r;
    float movimiento;
    float errorMove;
    float errorAngle;
    float weight;
    float step;
    float rotation;

    particle(float x, float y, float angulo, float paso, float rotacion, float errMove, float errAng) {
      angle     = angulo;
      direction = new PVector(cos(angle), sin(angle));
      position  = new PVector(x, y);
      r         = 5.0;
      step      = paso;
      rotation  = rotacion;
      errorMove = errMove;
      errorAngle = errAng;
    }

    particle(particle other) { // pueden modificar esto
      position   = new PVector(other.position.x, other.position.y);
      direction  = new PVector(other.direction.x, other.direction.y);
      angle      = other.angle;
      r          = other.r;
      movimiento = other.movimiento;
      errorMove  = other.errorMove;
      errorAngle = other.errorAngle;
      weight     = other.weight;
    }

    void calcWeight(float X, float Y, PVector dirObs, float movObs) {
      final float σ_pos = errorMove;
      final float σ_vel = errorMove;

      float ePosX = position.x - X;
      float ePosY = position.y - Y;
      float posQuad = ePosX*ePosX + ePosY*ePosY;

      float p_pos = exp(-posQuad / (2.0f * σ_pos * σ_pos));

      float Δx_obs = dirObs.x * movObs;
      float Δy_obs = dirObs.y * movObs;

      float Δx_par = direction.x * movimiento;
      float Δy_par = direction.y * movimiento;

      float eVelX  = Δx_par - Δx_obs;
      float eVelY  = Δy_par - Δy_obs;
      float velQuad = eVelX*eVelX + eVelY*eVelY;

      float p_vel = exp(-velQuad / (2.0f * σ_vel * σ_vel));

      float w = p_pos * p_vel;
      weight  = max(w, 1e-20f);
    }


    void borders() {
      if (position.x < -r) position.x = size+r;
      if (position.y < -r) position.y = size+r;
      if (position.x > size+r) position.x = -r;
      if (position.y > size+r) position.y = -r;
    }

    void draw() {
      float theta = direction.heading() + radians(90);
      pushMatrix();
      translate(position.x, position.y);
      rotate(theta);
      beginShape(TRIANGLES);
      vertex(0, -r*2);
      vertex(-r, r*2);
      vertex(r, r*2);
      endShape();
      popMatrix();

      position.x += direction.x*movimiento;
      position.y += direction.y*movimiento;
      borders();
      movimiento *= 0.95;
    }

    void right() {
      float angulo = rotation + randomGaussian()*errorAngle;
      angle += radians(angulo);
      direction = new PVector(cos(angle), sin(angle));
    }

    void left() {
      float angulo = rotation + randomGaussian()*errorAngle;
      angle -= radians(angulo);
      direction = new PVector(cos(angle), sin(angle));
    }

    void forward() {
      float amount = step+randomGaussian()*errorMove;
      movimiento += amount;
    }

    void backward() {
      float amount = step+randomGaussian()*errorMove;
      movimiento -= amount;
    }
  };

  Agente(int nparticles, Ambiente a, float x, float y, float angulo, float paso, float rotacion, float errMove, float errAng) {
    numParticulas = nparticles;
    hab = a;
    candidatos = new ArrayList<particle>();
    for (int i = 0; i < numParticulas; i++)
      candidatos.add(new particle(x, y, angulo, paso, rotacion, errMove, errAng));
  }


  void filtre(float X, float Y, PVector dirObs, float movObs) {
    for (particle p : candidatos) {
      float nAng = randomGaussian() * p.errorAngle * 0.30f;
      float nMov = randomGaussian() * p.errorMove  * 0.30f;

      p.angle = atan2(dirObs.y, dirObs.x) + radians(nAng);
      p.direction.set(cos(p.angle), sin(p.angle));

      p.movimiento = movObs + nMov;
      p.position.x += p.direction.x * p.movimiento;
      p.position.y += p.direction.y * p.movimiento;
      p.borders();
    }

    float sumW = 0;
    for (particle p : candidatos) {
      p.calcWeight(X, Y, dirObs, movObs);
      sumW += p.weight;
    }
    if (sumW == 0) {
      for (particle p : candidatos) p.weight = 1.0f/numParticulas;
      sumW = 1;
    }
    for (particle p : candidatos) p.weight /= sumW;

    ArrayList<particle> nuevos = new ArrayList<particle>();
    float r   = random(1.0f/numParticulas);
    float c   = candidatos.get(0).weight;
    int   i   = 0;

    float σRpos = 0.01f * size / sqrt(numParticulas);
    float σRang = 0.01f * TWO_PI / sqrt(numParticulas);

    for (int m = 0; m < numParticulas; m++) {
      float U = r + m * (1.0f/numParticulas);
      while (U > c) {
        i++;
        c += candidatos.get(i).weight;
      }

      particle hijo = new particle(candidatos.get(i));

      hijo.position.x += randomGaussian() * σRpos;
      hijo.position.y += randomGaussian() * σRpos;
      hijo.angle      += randomGaussian() * σRang;
      hijo.direction.set(cos(hijo.angle), sin(hijo.angle));

      hijo.movimiento += randomGaussian() * hijo.errorMove * 0.10f;
      hijo.weight      = 1.0f/numParticulas;

      nuevos.add(hijo);
    }
    candidatos = nuevos;
  }

  void left() {
    for (particle p : candidatos)
      p.left();

    hab.left();
    filtre(hab.senseX(), hab.senseY(), hab.senseDir(), hab.senseMove());
  }

  void right() {
    for (particle p : candidatos)
      p.right();

    hab.right();
    filtre(hab.senseX(), hab.senseY(), hab.senseDir(), hab.senseMove());
  }

  void forward() {
    for (particle p : candidatos)
      p.forward();

    hab.forward();
    filtre(hab.senseX(), hab.senseY(), hab.senseDir(), hab.senseMove());
  }

  void backward() {
    for (particle p : candidatos)
      p.backward();

    hab.backward();
    filtre(hab.senseX(), hab.senseY(), hab.senseDir(), hab.senseMove());
  }

  void draw() {
    fill(255, 255, 255);
    square(0, 0, size);
    for (particle p : candidatos)
      p.draw();
  }
};

Ambiente hab;
Agente   agente;

void setup() {
  size(1000, 500); // boxSize*24, boxSize*12, solo permite valores constantes
  background(255, 255, 255);
  stroke(0, 0, 0);

  float angle = random(TWO_PI);
  hab = new Ambiente(size/2, size/2, angle, 5.0, 5.0, 1.0, 1.0);
  agente = new Agente(50, hab, size/2, size/2, angle, 5.0, 5.0, 1.0, 1.0);

  print(angle);
}

void keyPressed() {
  if (key == CODED) {
    if (keyCode == LEFT) {
      agente.left();
    }
    if (keyCode == RIGHT) {
      agente.right();
    }
    if (keyCode == UP) {
      agente.forward();
    }
    if (keyCode == DOWN) {
      agente.backward();
    }
    redraw();
  }
}

void draw() {
  hab.draw();

  translate(size, 0);
  agente.draw();
}
