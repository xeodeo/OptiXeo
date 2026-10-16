<#
  OptiXeo - interfaz gráfica (WPF, viene con Windows: no instala nada).
  Toda la lógica de cambios, copias y restauración está en OptiXeo.ps1; esto solo la dibuja.
  El trabajo pesado corre en un hilo aparte para que la ventana no se congele.
#>
$ErrorActionPreference = 'Stop'
$IsDotSourced = $MyInvocation.InvocationName -eq '.'

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin -and -not $IsDotSourced) {
    Start-Process powershell -Verb RunAs -ArgumentList @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-WindowStyle', 'Hidden', '-File', "`"$PSCommandPath`"")
    exit
}

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase
$EnginePath = Join-Path $PSScriptRoot 'OptiXeo.ps1'
. $EnginePath
$AppsPath = Join-Path $PSScriptRoot 'OptiXeo-Apps.ps1'
. $AppsPath
$ErrorActionPreference = 'Continue'

# ============================================================================
#  DISEÑO
# ============================================================================
[xml]$Xaml = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="OptiXeo" Width="1300" Height="820" MinWidth="1120" MinHeight="660"
        WindowStartupLocation="CenterScreen" WindowStyle="None" AllowsTransparency="True"
        Background="Transparent" ResizeMode="CanResizeWithGrip" FontFamily="Segoe UI"
        UseLayoutRounding="True" TextOptions.TextFormattingMode="Display">
  <Window.Resources>
    <LinearGradientBrush x:Key="AccentGrad" StartPoint="0,0" EndPoint="1,1">
      <GradientStop Color="#7C5CFF" Offset="0"/>
      <GradientStop Color="#22D3EE" Offset="1"/>
    </LinearGradientBrush>

    <Style x:Key="Caption" TargetType="TextBlock">
      <Setter Property="FontSize" Value="10.5"/>
      <Setter Property="FontWeight" Value="SemiBold"/>
      <Setter Property="Foreground" Value="#5F687C"/>
    </Style>

    <Style x:Key="Panel" TargetType="Border">
      <Setter Property="Background" Value="#10131A"/>
      <Setter Property="BorderBrush" Value="#1C2130"/>
      <Setter Property="BorderThickness" Value="1"/>
      <Setter Property="CornerRadius" Value="12"/>
      <Setter Property="Padding" Value="18"/>
    </Style>

    <Style x:Key="Card" TargetType="Border">
      <Setter Property="Background" Value="#151922"/>
      <Setter Property="BorderBrush" Value="#1F2433"/>
      <Setter Property="BorderThickness" Value="1"/>
      <Setter Property="CornerRadius" Value="10"/>
      <Setter Property="Padding" Value="16,13"/>
      <Setter Property="Margin" Value="0,0,0,8"/>
      <Setter Property="Cursor" Value="Hand"/>
      <Style.Triggers>
        <Trigger Property="IsMouseOver" Value="True">
          <Setter Property="Background" Value="#1A1F2B"/>
          <Setter Property="BorderBrush" Value="#2C3448"/>
        </Trigger>
      </Style.Triggers>
    </Style>

    <Style x:Key="Switch" TargetType="CheckBox">
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="CheckBox">
            <Grid Width="44" Height="24" Background="Transparent">
              <Border x:Name="Track" CornerRadius="12" Background="#262C3B"/>
              <Ellipse x:Name="Knob" Width="18" Height="18" Fill="#AAB3C5" HorizontalAlignment="Left" Margin="3,0,0,0"/>
            </Grid>
            <ControlTemplate.Triggers>
              <Trigger Property="IsChecked" Value="True">
                <Setter TargetName="Track" Property="Background" Value="{StaticResource AccentGrad}"/>
                <Setter TargetName="Knob" Property="HorizontalAlignment" Value="Right"/>
                <Setter TargetName="Knob" Property="Margin" Value="0,0,3,0"/>
                <Setter TargetName="Knob" Property="Fill" Value="White"/>
              </Trigger>
              <Trigger Property="IsEnabled" Value="False">
                <Setter Property="Opacity" Value="0.3"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>

    <!-- Interruptor de algo que YA está aplicado/instalado: encendido en verde y bloqueado -->
    <Style x:Key="SwitchDone" TargetType="CheckBox">
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="CheckBox">
            <Grid Width="44" Height="24" Background="Transparent">
              <Border CornerRadius="12" Background="#2634D399" BorderBrush="#6634D399" BorderThickness="1"/>
              <Ellipse Width="18" Height="18" Fill="#34D399" HorizontalAlignment="Right" Margin="0,0,3,0"/>
            </Grid>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>

    <!-- Interruptor de algo aplicado que SÍ se puede deshacer: verde encendido; al apagarlo queda gris -->
    <Style x:Key="SwitchApplied" TargetType="CheckBox">
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="CheckBox">
            <Grid Width="44" Height="24" Background="Transparent">
              <Border x:Name="Track" CornerRadius="12" Background="#262C3B" BorderBrush="#FBBF24" BorderThickness="1"/>
              <Ellipse x:Name="Knob" Width="18" Height="18" Fill="#AAB3C5" HorizontalAlignment="Left" Margin="3,0,0,0"/>
            </Grid>
            <ControlTemplate.Triggers>
              <Trigger Property="IsChecked" Value="True">
                <Setter TargetName="Track" Property="Background" Value="#2634D399"/>
                <Setter TargetName="Track" Property="BorderBrush" Value="#6634D399"/>
                <Setter TargetName="Knob" Property="HorizontalAlignment" Value="Right"/>
                <Setter TargetName="Knob" Property="Margin" Value="0,0,3,0"/>
                <Setter TargetName="Knob" Property="Fill" Value="#34D399"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>

    <Style x:Key="Nav" TargetType="RadioButton">
      <Setter Property="Foreground" Value="#8A93A6"/>
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="Margin" Value="0,1"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="RadioButton">
            <Grid>
              <Border x:Name="Bd" CornerRadius="9" Background="Transparent" Padding="12,9">
                <ContentPresenter/>
              </Border>
              <Border x:Name="Bar" Width="3" CornerRadius="2" Margin="0,9" HorizontalAlignment="Left"
                      Background="{StaticResource AccentGrad}" Visibility="Hidden"/>
            </Grid>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True">
                <Setter TargetName="Bd" Property="Background" Value="#141821"/>
                <Setter Property="Foreground" Value="#E8ECF4"/>
              </Trigger>
              <Trigger Property="IsChecked" Value="True">
                <Setter TargetName="Bd" Property="Background" Value="#1A2030"/>
                <Setter TargetName="Bar" Property="Visibility" Value="Visible"/>
                <Setter Property="Foreground" Value="#FFFFFF"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>

    <Style x:Key="PrimaryBtn" TargetType="Button">
      <Setter Property="Foreground" Value="White"/>
      <Setter Property="FontWeight" Value="SemiBold"/>
      <Setter Property="FontSize" Value="13"/>
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="Button">
            <Border x:Name="Bd" CornerRadius="10" Background="{StaticResource AccentGrad}" Padding="22,10">
              <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="Bd" Property="Opacity" Value="0.88"/></Trigger>
              <Trigger Property="IsPressed" Value="True"><Setter TargetName="Bd" Property="Opacity" Value="0.75"/></Trigger>
              <Trigger Property="IsEnabled" Value="False"><Setter TargetName="Bd" Property="Opacity" Value="0.3"/></Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>

    <Style x:Key="SecondaryBtn" TargetType="Button">
      <Setter Property="Foreground" Value="#E8ECF4"/>
      <Setter Property="FontSize" Value="13"/>
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="Button">
            <Border x:Name="Bd" CornerRadius="10" Background="#181C27" BorderBrush="#2A3145" BorderThickness="1" Padding="18,9">
              <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="Bd" Property="Background" Value="#202637"/></Trigger>
              <Trigger Property="IsEnabled" Value="False"><Setter TargetName="Bd" Property="Opacity" Value="0.35"/></Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>

    <Style x:Key="GhostBtn" TargetType="Button">
      <Setter Property="Foreground" Value="#8A93A6"/>
      <Setter Property="FontSize" Value="12.5"/>
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="Button">
            <Border x:Name="Bd" CornerRadius="8" Background="Transparent" Padding="10,6">
              <ContentPresenter/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True">
                <Setter TargetName="Bd" Property="Background" Value="#181C27"/>
                <Setter Property="Foreground" Value="#FFFFFF"/>
              </Trigger>
              <Trigger Property="IsEnabled" Value="False"><Setter TargetName="Bd" Property="Opacity" Value="0.35"/></Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>

    <Style x:Key="SideBtn" TargetType="Button">
      <Setter Property="Foreground" Value="#8A93A6"/>
      <Setter Property="FontSize" Value="12.5"/>
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="Margin" Value="0,1"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="Button">
            <Border x:Name="Bd" CornerRadius="9" Background="Transparent" Padding="12,9">
              <StackPanel Orientation="Horizontal">
                <TextBlock Text="{Binding Tag, RelativeSource={RelativeSource TemplatedParent}}" FontFamily="Segoe MDL2 Assets"
                           FontSize="14" VerticalAlignment="Center" Margin="0,0,12,0"/>
                <ContentPresenter VerticalAlignment="Center"/>
              </StackPanel>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True">
                <Setter TargetName="Bd" Property="Background" Value="#141821"/>
                <Setter Property="Foreground" Value="#FFFFFF"/>
              </Trigger>
              <Trigger Property="IsEnabled" Value="False"><Setter TargetName="Bd" Property="Opacity" Value="0.35"/></Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>

    <Style x:Key="TitleBtn" TargetType="Button">
      <Setter Property="Foreground" Value="#8A93A6"/>
      <Setter Property="FontFamily" Value="Segoe MDL2 Assets"/>
      <Setter Property="FontSize" Value="10"/>
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="Button">
            <Border x:Name="Bd" Width="44" Height="32" CornerRadius="8" Background="Transparent">
              <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True">
                <Setter TargetName="Bd" Property="Background" Value="#1A1F2B"/>
                <Setter Property="Foreground" Value="#FFFFFF"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>

    <Style x:Key="CloseBtn" TargetType="Button" BasedOn="{StaticResource TitleBtn}">
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="Button">
            <Border x:Name="Bd" Width="44" Height="32" CornerRadius="8" Background="Transparent">
              <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True">
                <Setter TargetName="Bd" Property="Background" Value="#E5484D"/>
                <Setter Property="Foreground" Value="#FFFFFF"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>

    <Style x:Key="Bar" TargetType="ProgressBar">
      <Setter Property="Height" Value="8"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="ProgressBar">
            <Grid>
              <Border x:Name="PART_Track" CornerRadius="4" Background="#222837"/>
              <Border x:Name="PART_Indicator" CornerRadius="4" HorizontalAlignment="Left" Background="{StaticResource AccentGrad}"/>
            </Grid>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>

    <Style TargetType="ScrollBar">
      <Setter Property="Width" Value="8"/>
      <Setter Property="MinWidth" Value="8"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="ScrollBar">
            <Track x:Name="PART_Track" IsDirectionReversed="True">
              <Track.Thumb>
                <Thumb>
                  <Thumb.Template>
                    <ControlTemplate TargetType="Thumb">
                      <Border CornerRadius="4" Background="#2A3142"/>
                    </ControlTemplate>
                  </Thumb.Template>
                </Thumb>
              </Track.Thumb>
            </Track>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>

    <Style TargetType="ListBoxItem">
      <Setter Property="Foreground" Value="#E8ECF4"/>
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="ListBoxItem">
            <Border x:Name="Bd" CornerRadius="8" Background="Transparent" Padding="12,9" Margin="0,2">
              <ContentPresenter/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="Bd" Property="Background" Value="#1C2130"/></Trigger>
              <Trigger Property="IsSelected" Value="True"><Setter TargetName="Bd" Property="Background" Value="#29304A"/></Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>
  </Window.Resources>

  <Border CornerRadius="14" Background="#0B0D12" BorderBrush="#232836" BorderThickness="1">
    <Grid>
      <Grid.RowDefinitions>
        <RowDefinition Height="60"/>
        <RowDefinition Height="*"/>
      </Grid.RowDefinitions>

      <!-- Barra de título -->
      <Grid x:Name="TitleBar" Background="Transparent">
        <StackPanel Orientation="Horizontal" VerticalAlignment="Center" Margin="22,0,0,0">
          <Border Width="34" Height="34" CornerRadius="10" Background="{StaticResource AccentGrad}">
            <TextBlock Text="&#xE945;" FontFamily="Segoe MDL2 Assets" FontSize="17" Foreground="White"
                       HorizontalAlignment="Center" VerticalAlignment="Center"/>
          </Border>
          <StackPanel Margin="12,0,0,0" VerticalAlignment="Center">
            <TextBlock Text="OptiXeo" FontSize="16" FontWeight="SemiBold" Foreground="#F2F5FA"/>
            <TextBlock x:Name="SubTitle" Text="Optimizador a medida" FontSize="11" Foreground="#6B7488"/>
          </StackPanel>
        </StackPanel>
        <StackPanel Orientation="Horizontal" HorizontalAlignment="Right" VerticalAlignment="Top" Margin="0,10,10,0">
          <Button x:Name="BtnMin" Style="{StaticResource TitleBtn}" Content="&#xE921;"/>
          <Button x:Name="BtnClose" Style="{StaticResource CloseBtn}" Content="&#xE8BB;" Margin="4,0,0,0"/>
        </StackPanel>
      </Grid>

      <Grid Grid.Row="1" Margin="14,0,14,14">
        <Grid.ColumnDefinitions>
          <ColumnDefinition Width="230"/>
          <ColumnDefinition Width="*"/>
          <ColumnDefinition Width="310"/>
        </Grid.ColumnDefinitions>

        <!-- Barra lateral -->
        <DockPanel Grid.Column="0" Margin="0,0,14,0">
          <StackPanel DockPanel.Dock="Bottom">
            <TextBlock Text="HERRAMIENTAS" Style="{StaticResource Caption}" Margin="12,0,0,6"/>
            <Button x:Name="BtnTemp"   Style="{StaticResource SideBtn}" Tag="&#xE74D;" Content="Limpiar temporales"/>
            <Button x:Name="BtnWsl"    Style="{StaticResource SideBtn}" Tag="&#xE756;" Content="Liberar RAM de WSL"/>
            <Button x:Name="BtnRescan" Style="{StaticResource SideBtn}" Tag="&#xE72C;" Content="Volver a analizar"/>
            <Button x:Name="BtnFolder" Style="{StaticResource SideBtn}" Tag="&#xE8B7;" Content="Carpeta de copias"/>
            <Button x:Name="BtnReboot" Style="{StaticResource SideBtn}" Tag="&#xE777;" Content="Reiniciar PC"/>
          </StackPanel>
          <StackPanel>
            <TextBlock Text="CATEGORÍAS" Style="{StaticResource Caption}" Margin="12,4,0,6"/>
            <StackPanel x:Name="NavPanel"/>
          </StackPanel>
        </DockPanel>

        <!-- Lista principal -->
        <Border Grid.Column="1" CornerRadius="12" Background="#0F1218" BorderBrush="#1C2130" BorderThickness="1">
          <Grid>
            <Grid.RowDefinitions>
              <RowDefinition Height="Auto"/>
              <RowDefinition Height="*"/>
              <RowDefinition Height="Auto"/>
            </Grid.RowDefinitions>
            <Grid Margin="26,22,22,14">
              <StackPanel>
                <TextBlock x:Name="HdrTitle" Text="Todo" FontSize="24" FontWeight="SemiBold" Foreground="#F2F5FA"/>
                <TextBlock x:Name="HdrSub" Text="Analizando tu PC..." FontSize="12.5" Foreground="#8A93A6" Margin="0,4,0,0"/>
              </StackPanel>
              <StackPanel Orientation="Horizontal" HorizontalAlignment="Right" VerticalAlignment="Center">
                <Button x:Name="BtnRec"  Style="{StaticResource GhostBtn}" Content="Marcar recomendados"/>
                <Button x:Name="BtnNone" Style="{StaticResource GhostBtn}" Content="Desmarcar todo" Margin="4,0,0,0"/>
              </StackPanel>
            </Grid>
            <ScrollViewer Grid.Row="1" VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Disabled" Padding="26,0,18,10">
              <Grid>
                <StackPanel x:Name="ItemsPanel"/>
                <StackPanel x:Name="AppsPanel" Visibility="Collapsed"/>
                <StackPanel x:Name="DriversPanel" Visibility="Collapsed"/>
              </Grid>
            </ScrollViewer>
            <Border Grid.Row="2" BorderBrush="#1C2130" BorderThickness="0,1,0,0" Padding="26,14,22,14">
              <Grid>
                <StackPanel VerticalAlignment="Center" Margin="0,0,330,0">
                  <TextBlock x:Name="StatusText" Text="Listo" Foreground="#C9D1E0" FontSize="12.5" TextTrimming="CharacterEllipsis"/>
                  <ProgressBar x:Name="Progress" Style="{StaticResource Bar}" Height="4" Margin="0,8,0,0"
                               Width="260" HorizontalAlignment="Left" Visibility="Hidden"/>
                </StackPanel>
                <StackPanel Orientation="Horizontal" HorizontalAlignment="Right">
                  <Button x:Name="BtnRestore" Style="{StaticResource SecondaryBtn}" Content="Restaurar copia"/>
                  <Button x:Name="BtnApply" Style="{StaticResource PrimaryBtn}" Content="Aplicar" Margin="10,0,0,0" IsEnabled="False"/>
                </StackPanel>
              </Grid>
            </Border>
          </Grid>
        </Border>

        <!-- Panel derecho -->
        <Grid Grid.Column="2" Margin="14,0,0,0">
          <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
          </Grid.RowDefinitions>
          <Border Style="{StaticResource Panel}">
            <StackPanel>
              <DockPanel>
                <TextBlock Text="MEMORIA" Style="{StaticResource Caption}"/>
                <TextBlock Text="&#x25CF; en vivo" Foreground="#34D399" FontSize="10.5" HorizontalAlignment="Right"/>
              </DockPanel>
              <StackPanel Orientation="Horizontal" Margin="0,10,0,0">
                <TextBlock x:Name="RamUsed" Text="-" FontSize="34" FontWeight="SemiBold" Foreground="#F2F5FA"/>
                <TextBlock x:Name="RamTotal" FontSize="14" Foreground="#8A93A6" VerticalAlignment="Bottom" Margin="8,0,0,7"/>
              </StackPanel>
              <ProgressBar x:Name="RamBar" Style="{StaticResource Bar}" Margin="0,8,0,14" Maximum="100"/>
              <Grid>
                <Grid.ColumnDefinitions><ColumnDefinition/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
                <Grid.RowDefinitions><RowDefinition/><RowDefinition/><RowDefinition/></Grid.RowDefinitions>
                <TextBlock Text="Libre" Foreground="#8A93A6" FontSize="12" Margin="0,2"/>
                <TextBlock x:Name="RamFree" Grid.Column="1" Foreground="#E8ECF4" FontSize="12" Margin="0,2"/>
                <TextBlock Grid.Row="1" Text="Instalada" Foreground="#8A93A6" FontSize="12" Margin="0,2"/>
                <TextBlock x:Name="RamInst" Grid.Row="1" Grid.Column="1" Foreground="#E8ECF4" FontSize="12" Margin="0,2"/>
                <TextBlock Grid.Row="2" Text="Reservada para la iGPU" Foreground="#8A93A6" FontSize="12" Margin="0,2"/>
                <TextBlock x:Name="RamRes" Grid.Row="2" Grid.Column="1" Foreground="#FBBF24" FontSize="12" Margin="0,2"/>
              </Grid>
            </StackPanel>
          </Border>
          <Border Grid.Row="1" Style="{StaticResource Panel}" Margin="0,14,0,0">
            <StackPanel>
              <TextBlock Text="LO QUE MÁS CONSUME" Style="{StaticResource Caption}"/>
              <StackPanel x:Name="ProcPanel" Margin="0,10,0,0"/>
            </StackPanel>
          </Border>
          <Border Grid.Row="2" Style="{StaticResource Panel}" Margin="0,14,0,0">
            <DockPanel>
              <TextBlock DockPanel.Dock="Top" Text="REGISTRO" Style="{StaticResource Caption}"/>
              <ScrollViewer x:Name="LogScroll" Margin="0,8,0,0" VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Disabled">
                <StackPanel x:Name="LogPanel"/>
              </ScrollViewer>
            </DockPanel>
          </Border>
        </Grid>
      </Grid>

      <!-- Diálogo -->
      <Grid x:Name="Overlay" Grid.RowSpan="2" Background="#C8070910" Visibility="Collapsed">
        <Border Width="500" CornerRadius="14" Background="#141821" BorderBrush="#2A3145" BorderThickness="1"
                Padding="26,22" HorizontalAlignment="Center" VerticalAlignment="Center">
          <StackPanel>
            <TextBlock x:Name="DlgTitle" FontSize="18" FontWeight="SemiBold" Foreground="#F2F5FA"/>
            <ContentControl x:Name="DlgBody" Margin="0,12,0,20"/>
            <StackPanel Orientation="Horizontal" HorizontalAlignment="Right">
              <Button x:Name="DlgCancel" Style="{StaticResource SecondaryBtn}" Content="Cancelar"/>
              <Button x:Name="DlgOk" Style="{StaticResource PrimaryBtn}" Content="Aceptar" Margin="10,0,0,0"/>
            </StackPanel>
          </StackPanel>
        </Border>
      </Grid>
    </Grid>
  </Border>
</Window>
'@

$Win = [Windows.Markup.XamlReader]::Load((New-Object System.Xml.XmlNodeReader $Xaml))
$ui = @{}
$xNs = 'http://schemas.microsoft.com/winfx/2006/xaml'
foreach ($node in $Xaml.SelectNodes("//*[@*[local-name()='Name']]")) {
    $name = $node.GetAttribute('Name', $xNs)
    if ($name) { $ui[$name] = $Win.FindName($name) }
}

# ============================================================================
#  AYUDANTES DE DIBUJO
# ============================================================================
$BrushConv = New-Object Windows.Media.BrushConverter
function Brush($hex) { $BrushConv.ConvertFromString($hex) }

$LogColors = @{ Green = '#34D399'; Yellow = '#FBBF24'; Red = '#F87171'; Cyan = '#22D3EE'; White = '#E8ECF4'; Gray = '#9AA3B5'; DarkGray = '#6B7488' }

function New-Text($text, $size = 13, $color = '#E8ECF4', $weight = 'Normal') {
    $t = New-Object Windows.Controls.TextBlock
    $t.Text = $text; $t.FontSize = $size; $t.Foreground = Brush $color; $t.FontWeight = $weight
    $t.TextWrapping = 'Wrap'
    $t
}

function New-Pill($text, $bg, $fg) {
    $b = New-Object Windows.Controls.Border
    $b.CornerRadius = 6; $b.Padding = '8,3'; $b.Background = Brush $bg; $b.VerticalAlignment = 'Center'
    $t = New-Text $text 10.5 $fg 'SemiBold'
    $t.TextWrapping = 'NoWrap'
    $b.Child = $t
    $b
}

function Add-Log($msg, $color = 'Gray') {
    foreach ($line in ([string]$msg -split "`n")) {
        if (-not $line.Trim()) { continue }
        $col = if ($LogColors.ContainsKey([string]$color)) { $LogColors[[string]$color] } else { $LogColors.Gray }
        $t = New-Text $line.Trim() 11.5 $col
        $t.FontFamily = 'Consolas'; $t.Margin = '0,1'
        [void]$ui.LogPanel.Children.Add($t)
        # recuento para el resumen final (ventana de reinicio)
        $tl = $line.Trim()
        if ($tl -match '^(OK|DESHECHO|RESTAURADO)\b') { $script:RunOk++ }
        elseif ($tl -match '^FALLO') { $script:RunFail++ }
        if ($tl -match 'pide reiniciar') { $script:RunNeedsReboot = $true }
        if ($line -match 'OK|FALLO|RESTAURADO|Liberado|apagada|Copia|Instalando|YA ESTABA|terminada') { $ui.StatusText.Text = $line.Trim() }
    }
    $ui.LogScroll.ScrollToEnd()
}

# Título y descripción salen del texto "Why": la primera frase es el título.
function Split-Why($why) {
    $m = [regex]::Match($why, '^(.+?)[.:]\s+(.+)$')
    if ($m.Success) { return $m.Groups[1].Value, $m.Groups[2].Value }
    return $why.TrimEnd('.'), ''
}

$TypeNames = @{ Service = 'Servicio'; Task = 'Tarea'; Reg = 'Registro'; Startup = 'Inicio'; Appx = 'App'; Feature = 'Característica'; WslConfig = 'WSL'; Driver = 'Driver' }

function Get-TechLabel($it) {
    switch ($it.Type) {
        'Service'   { "$($it.Name)  →  $($it.Start)" }
        'Task'      { "$($it.Path)$($it.Name)" }
        'Reg'       { "$($it.Path)\$($it.Name) = $($it.Value)" }
        'Startup'   { "$($it.Hive)\...\Run\$($it.Name)" }
        'WslConfig' { $WslConfig }
        default     { $it.Name }
    }
}

$CatInfo = [ordered]@{
    Todo            = @('Todo', [char]0xE80F)
    Servicios       = @('Servicios', [char]0xE713)
    Tareas          = @('Tareas programadas', [char]0xE823)
    Privacidad      = @('Privacidad y anuncios', [char]0xE72E)
    Inicio          = @('Inicio de Windows', [char]0xE7E8)
    Apps            = @('Apps preinstaladas', [char]0xE71D)
    Caracteristicas = @('Características', [char]0xE8F1)
    WSL             = @('WSL', [char]0xE756)
    Drivers         = @('Drivers Master', [char]0xE90F)
    Programas       = @('Instalar programas', [char]0xE896)
}

# ============================================================================
#  CONSTRUCCIÓN DE LA LISTA
# ============================================================================
$script:AllItems = @(Get-ExpandedCatalog)
$script:Rows = New-Object System.Collections.ArrayList
$script:Headers = @{}
$script:NavBadges = @{}
$script:Filter = 'Todo'

function New-Row($it) {
    $card = New-Object Windows.Controls.Border
    $card.Style = $Win.FindResource('Card')

    $grid = New-Object Windows.Controls.Grid
    foreach ($w in 'Auto', '*', 'Auto') {
        $cd = New-Object Windows.Controls.ColumnDefinition
        $cd.Width = (New-Object Windows.GridLengthConverter).ConvertFromString($w)
        [void]$grid.ColumnDefinitions.Add($cd)
    }

    $chk = New-Object Windows.Controls.CheckBox
    $chk.Style = $Win.FindResource('Switch')
    $chk.VerticalAlignment = 'Center'; $chk.Margin = '0,0,16,0'; $chk.IsEnabled = $false
    [Windows.Controls.Grid]::SetColumn($chk, 0)

    $title, $desc = Split-Why $it.Why
    $text = New-Object Windows.Controls.StackPanel
    $line = New-Object Windows.Controls.WrapPanel
    $tt = New-Text $title 14 '#F2F5FA' 'SemiBold'
    $tt.Margin = '0,0,10,0'
    [void]$line.Children.Add($tt)
    $typePill = New-Pill $TypeNames[$it.Type].ToUpper() '#1E2433' '#8A93A6'
    $typePill.Margin = '0,0,6,0'
    [void]$line.Children.Add($typePill)
    if ($it.Rec) { [void]$line.Children.Add((New-Pill 'RECOMENDADO' '#267C5CFF' '#A996FF')) }
    [void]$text.Children.Add($line)
    if ($desc) {
        $d = New-Text $desc 12.5 '#9AA3B5'
        $d.Margin = '0,4,0,0'
        [void]$text.Children.Add($d)
    }
    $tech = New-Text (Get-TechLabel $it) 11 '#566074'
    $tech.FontFamily = 'Consolas'; $tech.Margin = '0,6,0,0'
    [void]$text.Children.Add($tech)
    [Windows.Controls.Grid]::SetColumn($text, 1)

    $pill = New-Pill 'ANALIZANDO' '#1E2433' '#6B7488'
    $pill.Margin = '14,0,0,0'
    [Windows.Controls.Grid]::SetColumn($pill, 2)

    [void]$grid.Children.Add($chk); [void]$grid.Children.Add($text); [void]$grid.Children.Add($pill)
    $card.Child = $grid

    $row = @{ Item = $it; Card = $card; Chk = $chk; Pill = $pill; Status = 'scan' }
    $card.Tag = $chk
    $chk.Tag = $row
    $chk.add_Checked({ param($s, $e) Update-UndoPill $s.Tag; Update-Selection })
    $chk.add_Unchecked({ param($s, $e) Update-UndoPill $s.Tag; Update-Selection })
    # clic en cualquier parte de la tarjeta = mover el interruptor
    $card.add_MouseLeftButtonUp({
        param($s, $e)
        $c = $s.Tag
        if ($c.IsEnabled -and -not $c.IsMouseOver) { $c.IsChecked = -not $c.IsChecked }
    })
    $row
}

# Interruptor verde fijo = ya hecho; normal = se puede elegir.
function Set-SwitchLook($chk, [bool]$done, $doneTip) {
    $chk.Style = $Win.FindResource($(if ($done) { 'SwitchDone' } else { 'Switch' }))
    $chk.ToolTip = if ($done) { $doneTip } else { $null }
    # el ToolTip de un control deshabilitado solo aparece con esto
    [Windows.Controls.ToolTipService]::SetShowOnDisabled($chk, $true)
}

function Set-Pill($row, $label, $bg, $fg) {
    $row.Pill.Background = Brush $bg
    $row.Pill.Child.Text = $label
    $row.Pill.Child.Foreground = Brush $fg
}

# Estados: pending (sin aplicar) · donerev (aplicado por OptiXeo, se puede deshacer)
#          done (ya estaba así antes: no hay copia de su valor original) · na (no existe)
function Set-RowStatus($row, $status) {
    $row.Status = $status
    switch ($status) {
        'pending' { Set-Pill $row 'PENDIENTE' '#26FBBF24' '#FBBF24'; $row.Card.Opacity = 1.0 }
        'done'    { Set-Pill $row 'APLICADO'  '#2234D399' '#34D399'; $row.Card.Opacity = 0.9 }
        'donerev' { $row.Card.Opacity = 1.0 }
        'na'      { Set-Pill $row 'NO EXISTE' '#1A8A93A6' '#6B7488'; $row.Card.Opacity = 0.4 }
    }
    if ($status -eq 'donerev') {
        $row.Chk.Style = $Win.FindResource('SwitchApplied')
        $row.Chk.ToolTip = 'Aplicado. Apágalo y pulsa Aplicar para deshacer solo este ajuste.'
        $row.Chk.IsEnabled = $true
        $row.Chk.IsChecked = $true
        Update-UndoPill $row
        return
    }
    $row.Chk.IsEnabled = ($status -eq 'pending')
    $row.Chk.IsChecked = $false
    Set-SwitchLook $row.Chk ($status -eq 'done') 'Ya estaba así antes de usar OptiXeo: no hay copia de su valor original para deshacerlo.'
}

# En un ajuste aplicado, apagar el interruptor = "se deshará"
function Update-UndoPill($row) {
    if (-not $row -or $row.Status -ne 'donerev') { return }
    if ($row.Chk.IsChecked) { Set-Pill $row 'APLICADO' '#2234D399' '#34D399' }
    else { Set-Pill $row 'SE DESHARÁ' '#26FBBF24' '#FBBF24' }
}

# Lo que cambiaría al pulsar Aplicar: pendientes encendidos + aplicados apagados.
function Get-TweakChanges {
    @{
        Apply = @($script:Rows | Where-Object { $_.Status -eq 'pending' -and $_.Chk.IsChecked })
        Undo  = @($script:Rows | Where-Object { $_.Status -eq 'donerev' -and -not $_.Chk.IsChecked })
    }
}

foreach ($cat in $CatInfo.Keys) {
    if ($cat -eq 'Drivers') {
        $cap = New-Text 'SISTEMA' 10.5 '#5F687C' 'SemiBold'
        $cap.Margin = '12,16,0,6'
        [void]$ui.NavPanel.Children.Add($cap)
    }
    if ($cat -eq 'Programas') {
        $cap = New-Text 'PROGRAMAS' 10.5 '#5F687C' 'SemiBold'
        $cap.Margin = '12,16,0,6'
        [void]$ui.NavPanel.Children.Add($cap)
    }
    $rb = New-Object Windows.Controls.RadioButton
    $rb.Style = $Win.FindResource('Nav'); $rb.GroupName = 'nav'; $rb.Tag = $cat
    $g = New-Object Windows.Controls.Grid
    foreach ($w in 'Auto', '*', 'Auto') {
        $cd = New-Object Windows.Controls.ColumnDefinition
        $cd.Width = (New-Object Windows.GridLengthConverter).ConvertFromString($w)
        [void]$g.ColumnDefinitions.Add($cd)
    }
    $ic = New-Object Windows.Controls.TextBlock
    $ic.Text = $CatInfo[$cat][1]; $ic.FontFamily = 'Segoe MDL2 Assets'; $ic.FontSize = 14
    $ic.VerticalAlignment = 'Center'; $ic.Margin = '0,0,12,0'
    $lb = New-Object Windows.Controls.TextBlock
    $lb.Text = $CatInfo[$cat][0]; $lb.FontSize = 13; $lb.VerticalAlignment = 'Center'
    [Windows.Controls.Grid]::SetColumn($lb, 1)
    $badge = New-Pill '' '#1E2433' '#8A93A6'
    $badge.Visibility = 'Collapsed'
    [Windows.Controls.Grid]::SetColumn($badge, 2)
    [void]$g.Children.Add($ic); [void]$g.Children.Add($lb); [void]$g.Children.Add($badge)
    $rb.Content = $g
    $script:NavBadges[$cat] = $badge
    $rb.add_Checked({ param($s, $e) Set-Filter $s.Tag })
    [void]$ui.NavPanel.Children.Add($rb)

    if ($cat -notin 'Todo', 'Programas', 'Drivers') {
        $h = New-Text $CatInfo[$cat][0].ToUpper() 10.5 '#5F687C' 'SemiBold'
        $h.Margin = '2,14,0,8'
        $script:Headers[$cat] = $h
        [void]$ui.ItemsPanel.Children.Add($h)
        foreach ($it in ($script:AllItems | Where-Object { $_.Cat -eq $cat })) {
            $row = New-Row $it
            [void]$script:Rows.Add($row)
            [void]$ui.ItemsPanel.Children.Add($row.Card)
        }
    }
}
# el análisis devuelve los estados en este mismo orden: tiene que coincidir con las tarjetas
$script:AllItems = @($script:Rows | ForEach-Object { $_.Item })

# ---- Tarjetas de programas (misma estética que las de ajustes) ----
$script:AppRows = New-Object System.Collections.ArrayList
function New-AppRow($app) {
    $idText = if ($app.Ids.Count -gt 2) { "$($app.Ids.Count) paquetes de winget ($($app.Ids[0]) ... $($app.Ids[-1]))" } else { $app.Ids -join ', ' }
    $fake = @{ Why = "$($app.Name). $($app.Desc)"; Type = 'Appx'; Rec = $false; Name = $idText }
    $row = New-Row $fake
    # la etiqueta de tipo muestra el grupo (MULTIMEDIA, JUEGOS...)
    $row.Card.Child.Children[1].Children[0].Children[1].Child.Text = $app.Group.ToUpper()
    $row.Pill.Child.Text = 'COMPROBANDO'
    $row.App = $app

    # icono original del programa a la izquierda del texto (icons\<Icon>.png, va dentro de la carpeta)
    $tile = New-Object Windows.Controls.Border
    $tile.Width = 44; $tile.Height = 44; $tile.CornerRadius = 10
    $tile.Background = Brush '#1C2130'; $tile.Margin = '0,0,14,0'; $tile.VerticalAlignment = 'Center'
    $iconFile = Join-Path $PSScriptRoot "icons\$($app.Icon).png"
    if ($app.Icon -and (Test-Path $iconFile)) {
        $bi = New-Object Windows.Media.Imaging.BitmapImage
        $bi.BeginInit(); $bi.UriSource = [Uri]$iconFile; $bi.CacheOption = 'OnLoad'; $bi.DecodePixelWidth = 64; $bi.EndInit()
        $img = New-Object Windows.Controls.Image
        $img.Source = $bi; $img.Width = 30; $img.Height = 30
        [Windows.Media.RenderOptions]::SetBitmapScalingMode($img, 'HighQuality')
        $tile.Child = $img
    } else {
        $letter = New-Text $app.Name.Substring(0, 1) 18 '#C9D1E0' 'SemiBold'
        $letter.HorizontalAlignment = 'Center'; $letter.VerticalAlignment = 'Center'
        $tile.Child = $letter
    }
    $grid = $row.Card.Child
    $text = $grid.Children[1]
    $grid.Children.Remove($text)
    $dock = New-Object Windows.Controls.DockPanel
    [Windows.Controls.DockPanel]::SetDock($tile, 'Left')
    [void]$dock.Children.Add($tile); [void]$dock.Children.Add($text)
    [Windows.Controls.Grid]::SetColumn($dock, 1)
    $grid.Children.Insert(1, $dock)
    $row
}

$lastGroup = $null
foreach ($app in $AppCatalog) {
    if ($app.Group -ne $lastGroup) {
        $h = New-Text $app.Group.ToUpper() 10.5 '#5F687C' 'SemiBold'
        $h.Margin = '2,14,0,8'
        [void]$ui.AppsPanel.Children.Add($h)
        $lastGroup = $app.Group
    }
    $row = New-AppRow $app
    [void]$script:AppRows.Add($row)
    [void]$ui.AppsPanel.Children.Add($row.Card)
}

function Set-AppStatus($row, $status) {
    $row.Status = $status
    $label, $bg, $fg, $op = switch ($status) {
        'missing'   { 'NO INSTALADO', '#2222D3EE', '#22D3EE', 1.0 }
        'partial'   { 'FALTA PARTE',  '#26FBBF24', '#FBBF24', 1.0 }
        'installed' { 'INSTALADO',    '#2234D399', '#34D399', 0.9 }
        'nowinget'  { 'SIN WINGET',   '#26F87171', '#F87171', 0.5 }
    }
    $row.Pill.Background = Brush $bg
    $row.Pill.Child.Text = $label
    $row.Pill.Child.Foreground = Brush $fg
    $row.Card.Opacity = $op
    $row.Chk.IsEnabled = ($status -in 'missing', 'partial')
    if (-not $row.Chk.IsEnabled) { $row.Chk.IsChecked = $false }
    Set-SwitchLook $row.Chk ($status -eq 'installed') 'Ya está instalado en este PC.'
}

# ============================================================================
#  DRIVERS  (filas dinamicas: se construyen tras el escaneo)
# ============================================================================
$script:DriverRows        = New-Object System.Collections.ArrayList
$script:DriverScanStarted = $false
$script:DriverScanDone    = $false
$script:DriverScanWanted  = $false

function New-DriverRow($d) {
    $fake = @{ Why = "$($d.Title). $($d.Detail)"; Type = 'Driver'; Rec = $false; Name = [string]$d.Vendor }
    $row = New-Row $fake
    $row.Driver = $d
    # la etiqueta de tipo muestra el origen/fabricante
    $row.Card.Child.Children[1].Children[0].Children[1].Child.Text = ([string]$d.Vendor).ToUpper()
    Set-DriverStatus $row $d.Kind
    $row
}

function Set-DriverStatus($row, $status) {
    $row.Status = $status
    $label, $bg, $fg, $op, $en = switch ($status) {
        'update'    { 'ACTUALIZAR',  '#2222D3EE', '#22D3EE', 1.0,  $true }
        'problem'   { 'SIN DRIVER',  '#26F87171', '#F87171', 1.0,  $false }
        'gpu'       { 'INFO',        '#1A8A93A6', '#8A93A6', 0.85, $false }
        'installed' { 'INSTALADO',   '#2234D399', '#34D399', 0.7,  $false }
        default     { 'INFO',        '#1A8A93A6', '#8A93A6', 0.85, $false }
    }
    $row.Pill.Background = Brush $bg
    $row.Pill.Child.Text = $label
    $row.Pill.Child.Foreground = Brush $fg
    $row.Card.Opacity = $op
    $row.Chk.IsEnabled = $en
    if (-not $en) { $row.Chk.IsChecked = $false }
}

function Build-DriverRows($items) {
    $ui.DriversPanel.Children.Clear()
    $script:DriverRows.Clear()
    if (-not $items -or @($items).Count -eq 0) {
        $t = New-Text 'No se detectaron drivers faltantes ni actualizaciones. Todo en orden.' 13 '#34D399'
        $t.Margin = '2,10,0,0'
        [void]$ui.DriversPanel.Children.Add($t)
        return
    }
    $groups = [ordered]@{
        problem = 'SIN DRIVER / CON PROBLEMA'
        update  = 'ACTUALIZACIONES (WINDOWS UPDATE)'
        gpu     = 'GPU - FUENTE OFICIAL DEL FABRICANTE'
    }
    foreach ($k in $groups.Keys) {
        $sub = @($items | Where-Object { $_.Kind -eq $k })
        if (-not $sub) { continue }
        $h = New-Text $groups[$k] 10.5 '#5F687C' 'SemiBold'
        $h.Margin = '2,14,0,8'
        [void]$ui.DriversPanel.Children.Add($h)
        foreach ($it in $sub) {
            $row = New-DriverRow $it
            [void]$script:DriverRows.Add($row)
            [void]$ui.DriversPanel.Children.Add($row.Card)
        }
    }
}

function Ensure-DriverScan {
    if ($script:DriverScanStarted) { return }
    if ($script:Busy) { $script:DriverScanWanted = $true; return }
    $script:DriverScanStarted = $true
    Start-Work 'driverscan' $null 'Buscando drivers (Windows Update, puede tardar)...'
}

function Request-DriverInstall {
    $sel = @($script:DriverRows | Where-Object { $_.Chk.IsChecked -and $_.Chk.IsEnabled })
    if (-not $sel) { return }
    $body = New-Object Windows.Controls.StackPanel
    [void]$body.Children.Add((New-Text 'Se descargan del catalogo oficial de Windows Update (firmados por Microsoft o el fabricante). Windows guarda el driver anterior; puedes revertir desde el Administrador de dispositivos.' 13 '#C9D1E0'))
    $list = New-Object Windows.Controls.StackPanel
    $list.Margin = '0,14,0,0'
    foreach ($r in $sel) {
        $t = New-Text ('•  ' + $r.Driver.Title) 12.5 '#E8ECF4'
        $t.Margin = '0,2'
        [void]$list.Children.Add($t)
    }
    [void]$body.Children.Add($list)
    if (Show-Dialog "Instalar $($sel.Count) drivers" $body 'Instalar ahora') {
        Start-Work 'driverinstall' @($sel | ForEach-Object { $_.Driver.Title }) 'Instalando drivers...' $sel.Count
    }
}

# ============================================================================
#  ESTADO DE LA VISTA
# ============================================================================
$script:Mode = 'tweaks'
function Get-ModeRows {
    switch ($script:Mode) {
        'apps'    { $script:AppRows }
        'drivers' { $script:DriverRows }
        default   { $script:Rows }
    }
}

function Set-Filter($cat) {
    $script:Filter = $cat
    $script:Mode = switch ($cat) { 'Programas' { 'apps' } 'Drivers' { 'drivers' } default { 'tweaks' } }
    $ui.HdrTitle.Text = $CatInfo[$cat][0]
    $ui.ItemsPanel.Visibility   = if ($script:Mode -eq 'tweaks')  { 'Visible' } else { 'Collapsed' }
    $ui.AppsPanel.Visibility    = if ($script:Mode -eq 'apps')    { 'Visible' } else { 'Collapsed' }
    $ui.DriversPanel.Visibility = if ($script:Mode -eq 'drivers') { 'Visible' } else { 'Collapsed' }
    $ui.BtnRestore.Visibility   = if ($script:Mode -eq 'tweaks')  { 'Visible' } else { 'Collapsed' }
    $ui.BtnRec.Content = switch ($script:Mode) { 'apps' { 'Marcar no instalados' } 'drivers' { 'Marcar actualizaciones' } default { 'Marcar recomendados' } }
    if ($script:Mode -eq 'tweaks') {
        foreach ($k in $script:Headers.Keys) {
            $script:Headers[$k].Visibility = if ($cat -eq 'Todo' -or $cat -eq $k) { 'Visible' } else { 'Collapsed' }
        }
        foreach ($r in $script:Rows) {
            $r.Card.Visibility = if ($cat -eq 'Todo' -or $r.Item.Cat -eq $cat) { 'Visible' } else { 'Collapsed' }
        }
    }
    if ($script:Mode -eq 'drivers') { Ensure-DriverScan }
    Update-Summary
    Update-Selection
}

function Set-Badge($cat, $n) {
    $b = $script:NavBadges[$cat]
    $b.Visibility = 'Visible'
    if ($n -gt 0) { $b.Child.Text = "$n"; $b.Background = Brush '#26FBBF24'; $b.Child.Foreground = Brush '#FBBF24' }
    else { $b.Child.Text = [string][char]0x2713; $b.Background = Brush '#2234D399'; $b.Child.Foreground = Brush '#34D399' }
}

function Update-Summary {
    $tweaksReady = -not ($script:Rows | Where-Object { $_.Status -eq 'scan' })
    if ($tweaksReady) {
        foreach ($cat in $CatInfo.Keys) {
            if ($cat -eq 'Programas' -or $cat -eq 'Drivers') { continue }
            Set-Badge $cat @($script:Rows | Where-Object { ($cat -eq 'Todo' -or $_.Item.Cat -eq $cat) -and $_.Status -eq 'pending' }).Count
        }
    }
    $appsReady = -not ($script:AppRows | Where-Object { $_.Status -eq 'scan' })
    if ($appsReady) { Set-Badge 'Programas' @($script:AppRows | Where-Object { $_.Status -in 'missing', 'partial' }).Count }
    if ($script:DriverScanDone) { Set-Badge 'Drivers' @($script:DriverRows | Where-Object { $_.Status -in 'update', 'problem' }).Count }

    if ($script:Mode -eq 'drivers') {
        if (-not $script:DriverScanDone) { $ui.HdrSub.Text = 'Buscando drivers en Windows Update...'; return }
        $u = @($script:DriverRows | Where-Object { $_.Status -eq 'update' }).Count
        $p = @($script:DriverRows | Where-Object { $_.Status -eq 'problem' }).Count
        $ui.HdrSub.Text = "$u actualizaciones  ·  $p con problema  ·  fuentes oficiales (Windows Update + fabricante)"
        return
    }
    if ($script:Mode -eq 'apps') {
        if (-not $appsReady) { $ui.HdrSub.Text = 'Comprobando qué programas tienes...'; return }
        if ($script:AppRows[0].Status -eq 'nowinget') { $ui.HdrSub.Text = "Este PC no tiene winget: instala 'Instalador de aplicación' desde Microsoft Store"; return }
        $i = @($script:AppRows | Where-Object Status -eq 'installed').Count
        $m = $script:AppRows.Count - $i
        $ui.HdrSub.Text = "$m por instalar  ·  $i instalados  ·  descarga oficial de cada fabricante vía winget"
        return
    }
    $visible = @($script:Rows | Where-Object { $script:Filter -eq 'Todo' -or $_.Item.Cat -eq $script:Filter })
    if (-not $tweaksReady) { $ui.HdrSub.Text = 'Analizando tu PC...'; return }
    $p = @($visible | Where-Object Status -eq 'pending').Count
    $d = @($visible | Where-Object { $_.Status -in 'done', 'donerev' }).Count
    $ui.HdrSub.Text = "$p pendientes  ·  $d aplicados  ·  $($visible.Count) en total"
}

function Update-Selection {
    if ($script:Mode -eq 'tweaks') { $c = Get-TweakChanges; $n = $c.Apply.Count + $c.Undo.Count }
    else { $n = @(Get-ModeRows | Where-Object { $_.Chk.IsChecked -and $_.Chk.IsEnabled }).Count }
    $ui.BtnApply.Content = switch ($script:Mode) {
        'apps'    { if ($n -eq 1) { 'Instalar 1 programa' } elseif ($n) { "Instalar $n programas" } else { 'Nada seleccionado' } }
        'drivers' { if ($n -eq 1) { 'Instalar 1 driver' }  elseif ($n) { "Instalar $n drivers" }  else { 'Nada seleccionado' } }
        default   { if ($n -eq 1) { 'Aplicar 1 cambio' }   elseif ($n) { "Aplicar $n cambios" }   else { 'Nada seleccionado' } }
    }
    $ui.BtnApply.IsEnabled = ($n -gt 0 -and -not $script:Busy)
}

function Update-Ram {
    try {
        $r = Get-RamInfo
        $ui.RamUsed.Text = '{0:N1} GB' -f $r.Used
        $ui.RamTotal.Text = 'de {0:N1} GB en uso' -f $r.Visible
        $ui.RamBar.Value = 100 * $r.Used / $r.Visible
        $ui.RamFree.Text = '{0:N1} GB' -f $r.Free
        $ui.RamInst.Text = '{0:N0} GB' -f $r.Installed
        $ui.RamRes.Text = '{0:N1} GB' -f ($r.Installed - $r.Visible)

        $procs = @(Get-TopProcesses 7)
        $max = ($procs | Measure-Object MB -Maximum).Maximum
        $ui.ProcPanel.Children.Clear()
        foreach ($p in $procs) {
            $g = New-Object Windows.Controls.Grid
            $g.Margin = '0,0,0,9'
            $name = if ($p.Count -gt 1) { "$($p.Name)  ×$($p.Count)" } else { $p.Name }
            $n = New-Text $name 12 '#C9D1E0'
            $mb = New-Text ('{0:N0} MB' -f $p.MB) 12 '#8A93A6'
            $mb.HorizontalAlignment = 'Right'
            $bar = New-Object Windows.Controls.ProgressBar
            $bar.Style = $Win.FindResource('Bar'); $bar.Height = 3; $bar.Margin = '0,20,0,0'
            $bar.Maximum = $max; $bar.Value = $p.MB
            [void]$g.Children.Add($n); [void]$g.Children.Add($mb); [void]$g.Children.Add($bar)
            [void]$ui.ProcPanel.Children.Add($g)
        }
    } catch { }
}

# ============================================================================
#  DIÁLOGO
# ============================================================================
function Show-Dialog($title, $body, $okText = 'Aceptar', [switch]$NoCancel, $CancelText = 'Cancelar') {
    $ui.DlgCancel.Content = $CancelText
    $ui.DlgTitle.Text = $title
    $ui.DlgBody.Content = if ($body -is [string]) { New-Text $body 13 '#C9D1E0' } else { $body }
    $ui.DlgOk.Content = $okText
    $ui.DlgCancel.Visibility = if ($NoCancel) { 'Collapsed' } else { 'Visible' }
    $script:DlgResult = $false
    $script:DlgFrame = New-Object Windows.Threading.DispatcherFrame
    $ui.Overlay.Visibility = 'Visible'
    [Windows.Threading.Dispatcher]::PushFrame($script:DlgFrame)
    $ui.Overlay.Visibility = 'Collapsed'
    $script:DlgResult
}
$ui.DlgOk.add_Click({ $script:DlgResult = $true; $script:DlgFrame.Continue = $false })
$ui.DlgCancel.add_Click({ $script:DlgFrame.Continue = $false })

# ============================================================================
#  TRABAJO EN SEGUNDO PLANO
# ============================================================================
$script:Queue = New-Object 'System.Collections.Concurrent.ConcurrentQueue[object]'
$script:Busy = $false

$WorkerScript = {
    param($EnginePath, $Kind, $Arg, $Q, $AppsPath)
    try {
        . $EnginePath
        . $AppsPath
        $script:LogSink = { param($m, $c) $Q.Enqueue(@{ Msg = [string]$m; Color = [string]$c }) }
        switch ($Kind) {
            'scan' {
                $idx = Get-BackupIndex
                $res = foreach ($it in $Arg) {
                    try {
                        $ok = Test-Applied $it (Get-State $it)
                        if ($null -eq $ok) { 'na' }
                        elseif ($ok) { if ($idx.ContainsKey((Get-ItemKey $it))) { 'donerev' } else { 'done' } }
                        else { 'pending' }
                    } catch { 'na' }
                }
                $Q.Enqueue(@{ Scan = @($res) })
            }
            'apply' {
                # $Arg = @{ Apply = ajustes a aplicar; Undo = @{Obj;Before} a deshacer }
                if ($Arg.Undo) { Undo-Items $Arg.Undo { $Q.Enqueue(@{ Step = $true }) } }
                if ($Arg.Apply) {
                    $todo = @(Get-Pending $Arg.Apply)
                    if ($todo) { Invoke-Changes $todo { $Q.Enqueue(@{ Step = $true }) } }
                }
                if (-not $Arg.Undo -and -not $Arg.Apply) { Say 'Nada que cambiar.' Green }
            }
            'restore' { Restore-Backup $Arg { $Q.Enqueue(@{ Step = $true }) } }
            'appscan' {
                $ids = Get-InstalledWingetIds
                $Q.Enqueue(@{ AppScan = @(foreach ($a in $Arg) { Get-AppStatus $a $ids }) })
            }
            'install' {
                foreach ($a in $Arg) { Install-App $a; $Q.Enqueue(@{ Step = $true }) }
                Say 'Instalación terminada.' Cyan
            }
            'temp'    { Clear-Temp }
            'wsl'     { & wsl.exe --shutdown | Out-Null; Say 'VM de WSL apagada.' Green }
            'driverscan'    { $Q.Enqueue(@{ DriverScan = @(Get-DriverItems) }) }
            'driverinstall' { Install-DriverUpdates $Arg { $Q.Enqueue(@{ Step = $true }) } }
        }
    } catch {
        $Q.Enqueue(@{ Error = $_.Exception.Message })
    } finally {
        $Q.Enqueue(@{ Done = $true })
    }
}

function Set-Busy($on, $text) {
    $script:Busy = $on
    foreach ($b in 'BtnRestore', 'BtnTemp', 'BtnWsl', 'BtnRescan', 'BtnRec', 'BtnNone', 'BtnReboot') { $ui[$b].IsEnabled = -not $on }
    $ui.Progress.Visibility = if ($on) { 'Visible' } else { 'Hidden' }
    if ($text) { $ui.StatusText.Text = $text }
    Update-Selection
}

function Show-RebootPrompt {
    $ok = [int]$script:RunOk; $fail = [int]$script:RunFail
    if ($ok -eq 0) { return }   # no cambió nada: no hace falta reiniciar

    $grid = New-Object Windows.Controls.Grid
    foreach ($w in 'Auto', '*') {
        $cd = New-Object Windows.Controls.ColumnDefinition
        $cd.Width = (New-Object Windows.GridLengthConverter).ConvertFromString($w)
        [void]$grid.ColumnDefinitions.Add($cd)
    }
    $circle = New-Object Windows.Controls.Border
    $circle.Width = 60; $circle.Height = 60; $circle.CornerRadius = 30
    $circle.Background = $Win.FindResource('AccentGrad'); $circle.Margin = '0,2,18,0'; $circle.VerticalAlignment = 'Top'
    $glyph = New-Object Windows.Controls.TextBlock
    $glyph.Text = [string][char]0xE777; $glyph.FontFamily = 'Segoe MDL2 Assets'; $glyph.FontSize = 26
    $glyph.Foreground = Brush '#FFFFFF'; $glyph.HorizontalAlignment = 'Center'; $glyph.VerticalAlignment = 'Center'
    $circle.Child = $glyph
    [void]$grid.Children.Add($circle)

    $right = New-Object Windows.Controls.StackPanel
    [Windows.Controls.Grid]::SetColumn($right, 1)
    $pills = New-Object Windows.Controls.WrapPanel
    $okLabel = if ($ok -eq 1) { '1 cambio correcto' } else { "$ok cambios correctos" }
    $p1 = New-Pill ([string][char]0x2713 + '  ' + $okLabel.ToUpper()) '#2234D399' '#34D399'
    $p1.Margin = '0,0,6,0'
    [void]$pills.Children.Add($p1)
    if ($fail) { [void]$pills.Children.Add((New-Pill ([string][char]0x2715 + "  $fail CON ERROR (mira el registro)") '#26F87171' '#F87171')) }
    [void]$right.Children.Add($pills)

    $why = switch ($script:RunKind) {
        'install'       { 'Algunas librerías, como Visual C++, piden reiniciar para quedar listas.' }
        'driverinstall' { 'Los drivers nuevos se cargan al reiniciar.' }
        default         { 'Los servicios, las apps y las características de Windows terminan de aplicarse al reiniciar. Hasta entonces, algunos cambios pueden no notarse.' }
    }
    $t1 = New-Text $why 13 '#C9D1E0'
    $t1.Margin = '0,12,0,0'
    [void]$right.Children.Add($t1)
    $t2 = New-Text 'Guarda lo que tengas abierto antes de reiniciar.' 12 '#8A93A6'
    $t2.Margin = '0,8,0,0'
    [void]$right.Children.Add($t2)
    [void]$grid.Children.Add($right)

    if (Show-Dialog 'Listo · se recomienda reiniciar' $grid 'Reiniciar ahora' -CancelText 'Más tarde') {
        Restart-Computer -Force
    } else {
        $ui.BtnReboot.Content = 'Reiniciar PC  ·  pendiente'
        $ui.BtnReboot.Foreground = Brush '#FBBF24'
        $ui.StatusText.Text = 'Reinicio pendiente: puedes hacerlo cuando quieras desde Herramientas'
    }
}

function Start-Work($kind, $arg, $text, $steps = 0) {
    if ($script:Busy) { return }
    $script:Kind = $kind
    if ($kind -in 'apply', 'restore', 'install', 'driverinstall') {
        $script:RunKind = $kind; $script:RunOk = 0; $script:RunFail = 0; $script:RunNeedsReboot = $false
    }
    $ui.Progress.IsIndeterminate = ($steps -eq 0)
    $ui.Progress.Maximum = [math]::Max($steps, 1); $ui.Progress.Value = 0
    Set-Busy $true $text
    $script:Runspace = [runspacefactory]::CreateRunspace()
    $script:Runspace.Open()
    $script:Worker = [powershell]::Create()
    $script:Worker.Runspace = $script:Runspace
    [void]$script:Worker.AddScript($WorkerScript).AddArgument($EnginePath).AddArgument($kind).AddArgument($arg).AddArgument($script:Queue).AddArgument($AppsPath)
    $script:Handle = $script:Worker.BeginInvoke()
}

function Complete-Work {
    try { $script:Worker.EndInvoke($script:Handle) | Out-Null } catch { }
    $script:Worker.Dispose(); $script:Runspace.Dispose()
    $kind = $script:Kind
    Set-Busy $false
    if ($kind -eq 'scan') {
        $ui.StatusText.Text = 'Análisis completo'
        if (-not $script:FirstScanDone) {
            $script:FirstScanDone = $true
            foreach ($r in $script:Rows) { if ($r.Status -eq 'pending' -and $r.Item.Rec) { $r.Chk.IsChecked = $true } }
        }
        # tras el primer análisis se comprueba qué programas hay instalados
        if (-not $script:AppScanDone) { Start-Work 'appscan' $AppCatalog 'Comprobando programas instalados...' }
    } elseif ($kind -eq 'appscan') {
        $script:AppScanDone = $true
        $ui.StatusText.Text = 'Análisis completo'
    } elseif ($kind -in 'apply', 'restore') {
        $script:RebootPromptPending = $true
        Start-Work 'scan' $script:AllItems 'Comprobando el resultado...'
    } elseif ($kind -eq 'install') {
        if ($script:RunNeedsReboot) { $script:RebootPromptPending = $true }
        Start-Work 'appscan' $AppCatalog 'Comprobando lo instalado...'
    } elseif ($kind -eq 'driverscan') {
        $ui.StatusText.Text = 'Análisis de drivers completo'
    } elseif ($kind -eq 'driverinstall') {
        $script:RebootPromptPending = $true
        $script:DriverScanDone = $false
        Start-Work 'driverscan' $null 'Re-analizando drivers...'
    }
    if ($script:DriverScanWanted -and -not $script:Busy) { $script:DriverScanWanted = $false; Ensure-DriverScan }
    # la ventana de reinicio sale cuando ya terminó el re-análisis (así detrás se ve todo actualizado)
    if ($script:RebootPromptPending -and -not $script:Busy) {
        $script:RebootPromptPending = $false
        # fuera del tick del temporizador, para no abrir el diálogo dentro de él
        [void]$Win.Dispatcher.BeginInvoke([action]{ Show-RebootPrompt })
    }
    Update-Ram
}

$Timer = New-Object Windows.Threading.DispatcherTimer
$Timer.Interval = [TimeSpan]::FromMilliseconds(120)
$Timer.add_Tick({
    $m = $null
    while ($script:Queue.TryDequeue([ref]$m)) {
        if ($m.ContainsKey('Msg')) { Add-Log $m.Msg $m.Color }
        elseif ($m.ContainsKey('Step')) { $ui.Progress.Value++ }
        elseif ($m.ContainsKey('Error')) { Add-Log "Error: $($m.Error)" 'Red' }
        elseif ($m.ContainsKey('Scan')) {
            for ($i = 0; $i -lt $script:Rows.Count; $i++) { Set-RowStatus $script:Rows[$i] $m.Scan[$i] }
            Update-Summary
        }
        elseif ($m.ContainsKey('AppScan')) {
            for ($i = 0; $i -lt $script:AppRows.Count; $i++) { Set-AppStatus $script:AppRows[$i] $m.AppScan[$i] }
            Update-Summary
            Update-Selection
        }
        elseif ($m.ContainsKey('DriverScan')) {
            $script:DriverScanDone = $true
            Build-DriverRows $m.DriverScan
            Update-Summary
            Update-Selection
        }
        elseif ($m.ContainsKey('Done')) { Complete-Work }
    }
})

$RamTimer = New-Object Windows.Threading.DispatcherTimer
$RamTimer.Interval = [TimeSpan]::FromSeconds(3)
$RamTimer.add_Tick({ Update-Ram })

# ============================================================================
#  BOTONES
# ============================================================================
$ui.TitleBar.add_MouseLeftButtonDown({ $Win.DragMove() })
$ui.BtnMin.add_Click({ $Win.WindowState = 'Minimized' })
$ui.BtnClose.add_Click({ $Win.Close() })

$ui.BtnRec.add_Click({
    if ($script:Mode -eq 'apps') {
        foreach ($r in $script:AppRows) { if ($r.Chk.IsEnabled) { $r.Chk.IsChecked = $true } }
    } elseif ($script:Mode -eq 'drivers') {
        foreach ($r in $script:DriverRows) { if ($r.Chk.IsEnabled) { $r.Chk.IsChecked = $true } }
    } else {
        # solo los pendientes: los ya aplicados no se tocan (apagarlos = deshacer)
        foreach ($r in $script:Rows) { if ($r.Status -eq 'pending') { $r.Chk.IsChecked = [bool]$r.Item.Rec } }
    }
})
$ui.BtnNone.add_Click({
    foreach ($r in (Get-ModeRows)) {
        if ($r.Status -eq 'pending') { $r.Chk.IsChecked = $false }       # ajustes sin aplicar
        elseif ($r.Status -eq 'donerev') { $r.Chk.IsChecked = $true }    # cancela los "se deshará"
        elseif ($script:Mode -ne 'tweaks') { $r.Chk.IsChecked = $false } # programas / drivers
    }
})

function Request-Install {
    $sel = @($script:AppRows | Where-Object { $_.Chk.IsChecked -and $_.Chk.IsEnabled })
    if (-not $sel) { return }
    $body = New-Object Windows.Controls.StackPanel
    [void]$body.Children.Add((New-Text 'Se descargan de la web oficial de cada fabricante con winget, que comprueba cada archivo antes de instalarlo. Tarda según tu conexión; puedes seguir usando el PC.' 13 '#C9D1E0'))
    $list = New-Object Windows.Controls.StackPanel
    $list.Margin = '0,14,0,0'
    foreach ($r in $sel) {
        $t = New-Text ('•  ' + $r.App.Name) 12.5 '#E8ECF4'
        $t.Margin = '0,2'
        [void]$list.Children.Add($t)
    }
    [void]$body.Children.Add($list)
    if (Show-Dialog "Instalar $($sel.Count) programas" $body 'Instalar ahora') {
        Start-Work 'install' @($sel | ForEach-Object { $_.App }) 'Instalando programas...' $sel.Count
    }
}

$ui.BtnApply.add_Click({
    if ($script:Mode -eq 'apps') { Request-Install; return }
    if ($script:Mode -eq 'drivers') { Request-DriverInstall; return }
    $c = Get-TweakChanges
    $total = $c.Apply.Count + $c.Undo.Count
    if (-not $total) { return }

    # estado anterior de cada ajuste a deshacer, sacado de las copias
    $undo = @()
    if ($c.Undo.Count) {
        $idx = Get-BackupIndex
        $undo = @(foreach ($r in $c.Undo) {
            $before = $idx[(Get-ItemKey $r.Item)]
            if ($before) { @{ Obj = $r.Item; Before = $before } }
        })
    }

    $body = New-Object Windows.Controls.StackPanel
    $intro = if ($c.Apply.Count) { 'Antes de aplicar se crea un punto de restauración y una copia de cada valor.' } else { 'Cada ajuste vuelve al valor que tenía antes de que OptiXeo lo cambiara.' }
    [void]$body.Children.Add((New-Text $intro 13 '#C9D1E0'))
    $sv = New-Object Windows.Controls.ScrollViewer
    $sv.MaxHeight = 240; $sv.Margin = '0,10,0,0'; $sv.VerticalScrollBarVisibility = 'Auto'
    $list = New-Object Windows.Controls.StackPanel
    foreach ($grp in @(@('SE APLICARÁ', $c.Apply, '#22D3EE'), @('SE DESHARÁ', $c.Undo, '#FBBF24'))) {
        if (-not $grp[1].Count) { continue }
        $h = New-Text $grp[0] 10.5 $grp[2] 'SemiBold'
        $h.Margin = '0,8,0,4'
        [void]$list.Children.Add($h)
        foreach ($r in $grp[1]) {
            $t = New-Text ('•  ' + (Split-Why $r.Item.Why)[0]) 12.5 '#E8ECF4'
            $t.Margin = '0,2'
            [void]$list.Children.Add($t)
        }
    }
    $sv.Content = $list
    [void]$body.Children.Add($sv)
    $title = if ($total -eq 1) { '1 cambio' } else { "$total cambios" }
    if (Show-Dialog $title $body 'Confirmar') {
        $arg = @{ Apply = @($c.Apply | ForEach-Object { $_.Item }); Undo = $undo }
        Start-Work 'apply' $arg 'Aplicando cambios...' $total
    }
})

$ui.BtnRestore.add_Click({
    $files = Get-Backups
    if (-not $files) { [void](Show-Dialog 'Sin copias' 'Todavía no hay copias de seguridad: se crean al aplicar cambios.' 'Entendido' -NoCancel); return }
    $lb = New-Object Windows.Controls.ListBox
    $lb.Background = Brush '#0F1218'; $lb.BorderThickness = 0; $lb.MaxHeight = 260
    foreach ($f in $files) {
        $n = try { $j = Get-Content $f.FullName -Raw | ConvertFrom-Json; @($j).Count } catch { '?' }
        $item = New-Object Windows.Controls.ListBoxItem
        $item.Content = '{0:dd/MM/yyyy  HH:mm}   ·   {1} cambios' -f $f.LastWriteTime, $n
        $item.Tag = $f.FullName
        [void]$lb.Items.Add($item)
    }
    $lb.SelectedIndex = 0
    $body = New-Object Windows.Controls.StackPanel
    [void]$body.Children.Add((New-Text 'Elige la copia: todo lo que cambió esa vez vuelve a como estaba.' 13 '#C9D1E0'))
    $lb.Margin = '0,12,0,0'
    [void]$body.Children.Add($lb)
    if ((Show-Dialog 'Restaurar copia' $body 'Restaurar') -and $lb.SelectedItem) {
        $path = $lb.SelectedItem.Tag
        $count = try { $j = Get-Content $path -Raw | ConvertFrom-Json; @($j).Count } catch { 0 }
        Start-Work 'restore' $path 'Restaurando...' $count
    }
})

$ui.BtnTemp.add_Click({
    if (Show-Dialog 'Limpiar temporales' 'Borra los archivos de más de 1 día en las carpetas temporales de tu usuario y de Windows. Esto no se puede deshacer, pero ahí no hay nada tuyo.' 'Limpiar') {
        Start-Work 'temp' $null 'Limpiando temporales...'
    }
})
$ui.BtnWsl.add_Click({
    if (Show-Dialog 'Liberar RAM de WSL' 'Apaga la máquina virtual de WSL (vmmem). Orca y todo lo que corra en Ubuntu se cerrará; vuelve a arrancar solo cuando lo abras.' 'Apagar WSL') {
        Start-Work 'wsl' $null 'Apagando WSL...'
    }
})
$ui.BtnRescan.add_Click({ Start-Work 'scan' $script:AllItems 'Analizando...' })
$ui.BtnReboot.add_Click({
    if (Show-Dialog 'Reiniciar el PC' 'Se cerrarán todos los programas abiertos. Guarda lo que tengas pendiente antes de continuar.' 'Reiniciar ahora') {
        Restart-Computer -Force
    }
})
$ui.BtnFolder.add_Click({
    New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null
    Start-Process explorer.exe $BackupDir
})

# ============================================================================
#  ARRANQUE
# ============================================================================
try {
    $cpu = (Get-CimInstance Win32_Processor | Select-Object -First 1).Name.Trim()
    $osName = (Get-CimInstance Win32_OperatingSystem).Caption -replace 'Microsoft ', ''
    $ui.SubTitle.Text = "$cpu  ·  $osName"
} catch { }

$Win.add_ContentRendered({
    Update-Ram
    Add-Log 'OptiXeo listo. Analizando tu PC...' Cyan
    Start-Work 'scan' $script:AllItems 'Analizando tu PC...'
})
$Win.add_Closed({ $Timer.Stop(); $RamTimer.Stop() })
$Timer.Start()
$RamTimer.Start()
$ui.NavPanel.Children[0].IsChecked = $true
Update-Selection

if (-not $IsDotSourced) { [void]$Win.ShowDialog() }
