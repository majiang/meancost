import std.math;

void main()
{
    import std.algorithm;
    import std.stdio;
    foreach (mu; [-0.03, -0.02, -0.01, 0, 0.01, 0.02, 0.03, 0.04, 0.05, 0.06, 0.07])
    foreach (sigma; [0.01, 0.02, 0.03, 0.04, 0.06, 0.08, 0.12, 0.16, 0.24, 0.32, 0.48])
    foreach (duration; [5, 10, 15, 20, 25, 30])
    foreach (rate; [-0.24, -0.16, -0.12, -0.08, -0.06, -0.04, -0.02, -0.01, 0, 0.01, 0.02, 0.04, 0.06, 0.08, 0.12, 0.16, 0.24])
    {
        enum size_t trial = 10000;
        auto results = new real[trial];
        auto betting = new ExponentialBetting(duration, rate);
        results.fill(Scenario(mu, sigma).simulate(betting));
        immutable auto totalBet = betting.totalBet;
        results.sort;
        foreach (i; [1, 10, 100, 1000, 5000])
        {
            "%f\t%f\t%d\t%f\t%d\t%f".writefln(
                    mu, sigma, duration, rate,
                    i, results[i] / totalBet
                );
        }
    }
}
interface Betting
{
    int opApply(scope int delegate(real) dg);
    final real totalBet()
    {
        real ret = 0;
        foreach (bet; this)
            ret += bet;
        return ret;
    }
}
version (none)
class ConstantBetting : Betting
{
    this (size_t duration)
    {
        this.duration = duration;
    }
    int opApply(scope int delegate(real) dg)
    {
        foreach (i; 0..duration)
        {
            if (auto r = dg(real(1)))
                return r;
        }
        return 0;
    }
    size_t duration;
}
class ExponentialBetting : Betting
{
    this (size_t duration, real rate)
    {
        this.duration = duration;
        this.rate = rate;
    }
    int opApply(scope int delegate(real) dg)
    {
        foreach (i; 0..duration)
        {
            if (auto r = dg(exp(rate * i)))
                return r;
        }
        return 0;
    }
    size_t duration;
    real rate;
}
auto simulate(Scenario scenario, Betting betting)
{
    struct Result
    {
        Scenario scenario;
        Betting betting;
        enum empty = false;
        real _front;
        const front()
        {
            return _front;
        }
        auto popFront()
        {
            real result = 0;
            foreach (bet; betting)
            {
                result += bet;
                result *= scenario.step;
            }
            _front = result;
            return this;
        }
    }
    return Result(scenario, betting).popFront;
}

struct Scenario
{
    import std.random;
    import std.mathspecial;
    this (real mu, real sigma)
    {
        this (mu, sigma, uints2ulong(unpredictableSeed, unpredictableSeed));
    }
    this (real mu, real sigma, ulong seed)
    {
        this.mu = mu;
        this.sigma = sigma;
        this.prng.seed(seed);
    }
    real mu, sigma;
    auto step()
    {
        return (prng.uniform01!real.normalDistributionInverse * sigma + mu).exp;
    }
private:
    Mt19937_64 prng;
}

ulong uints2ulong(uint x, uint y)
{
    ulong ret;
    foreach (i; 0..32)
    {
        ret <<= 1;
        ret |= x & 1;
        ret <<= 1;
        ret |= y & 1;
        x >>= 1;
        y >>= 1;
    }
    return ret;
}
