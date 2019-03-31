require 'traits'

describe 'traits' do
  it 'can be used by a class' do
    attacker = Trait.new do
      def attack_points
        10
      end
    end
    warrior_class = Class.new do
      use(attacker)
    end

    warrior = warrior_class.new

    expect(warrior.attack_points).to eq(10)
  end

  it 'can be composed' do
    attacker = Trait.new do
      def attack_points
        10
      end
    end
    defender = Trait.new do
      def defense_points
        20
      end
    end
    warrior_class = Class.new do
      use(attacker + defender)
    end

    warrior = warrior_class.new

    expect(warrior.attack_points).to eq(10)
    expect(warrior.defense_points).to eq(20)
  end

  it 'can exclude single methods' do
    character = Trait.new do
      def attack_points
        10
      end

      def defense_points
        20
      end
    end
    attacker = character - :defense_points

    warrior_class = Class.new do
      use(attacker)
    end

    warrior = warrior_class.new

    expect(warrior.attack_points).to eq(10)
    expect { warrior.defense_points }.to raise_error(NoMethodError)
  end

  it 'can exclude multiple methods' do
    character = Trait.new do
      def attack_points
        10
      end

      def defense_points
        20
      end
    end
    attacker = character - [:defense_points, :attack_points]

    warrior_class = Class.new do
      use(attacker)
    end

    warrior = warrior_class.new

    expect { warrior.attack_points }.to raise_error(NoMethodError)
    expect { warrior.defense_points }.to raise_error(NoMethodError)
  end

  it 'can alias methods' do
    attacker = Trait.new do
      def attack_points
        10
      end
    end
    character = attacker & { defense_points: :attack_points }

    warrior_class = Class.new do
      use(character)
    end

    warrior = warrior_class.new

    expect(warrior.attack_points).to eq(10)
    expect(warrior.defense_points).to eq(10)
  end

  it 'detects conflicts when including multiple traits that define the same methods' do
    attacker = Trait.new do
      def attack_points
        10
      end
    end
    soldier = Trait.new do
      def attack_points
        20
      end
    end

    expect do
      Class.new do
        use(attacker)
        use(soldier)
      end
    end.to raise_error(TraitConflict)
  end

  it 'detects conflicts when including a trait that defines the same method twice' do
    attacker = Trait.new do
      def attack_points
        10
      end
    end
    soldier = Trait.new do
      def attack_points
        20
      end
    end

    expect do
      Class.new do
        use(attacker + soldier)
      end
    end.to raise_error(TraitConflict)
  end

  it 'can use modules as traits' do
    attacker = Module.new do
      def attack_points
        10
      end
    end
    defender = Module.new do
      def defense_points
        20
      end

      def life
        30
      end
    end
    warrior_class = Class.new do
      use(attacker + defender - :life)
    end

    warrior = warrior_class.new

    expect(warrior.attack_points).to eq(10)
    expect(warrior.defense_points).to eq(20)
    expect { warrior.life }.to raise_error(NoMethodError)
  end
end