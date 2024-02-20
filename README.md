<div style=" color: black; font-size: 40px; text-align: center; fond-weight: bold">
    Bus Protocol Implementation
</div>

<ol style=" color: black; font-size: 20px; fond-weight: bold">
    <li>UART ✅</li>
    <li>
        <p>
            SPI：   <ul>
            <li>Synchrounus Comunication Interface;</li>
            <li>Full Duplex;</li>
            <li>The master device controls the clock signal,which determines when data can change and when it's ready for reading.</li>
            <li>Four wire interface. (Serial Clock, Master out Slave in, Master in Slave out, Slave Select)</li>
            <li>Serial clock can go up to 1/2 of system clock, typical serial clock is 1/4 of system clock.</li>
            <li>{CPOL CPHA} defines 4 modes, {0,0} => {SCLK start from 0, Data samples at the first edge},  {0,1}, {1,0} => ..., {1,1} => {SCLK start from 1, Data samples at the second edge}</li>
            </ul>
        </p>
    </li>
    <li>I2C</li>
    <li>APB</li>
    <li>AXI</li>
    <li>AHB</li>
    <li>Whishbone</li>

</ol>
